import CoreLocation
import UIKit

enum StartRefusal: Error {
  case noPermission, noBackground
}

final class LocationEngine: NSObject {
  private static let underTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
  private static let stopDrain: TimeInterval = 10

  var onEvent: (([String: Any]) -> Void)?
  let permissions: PermissionDesk

  private let clock: Clock
  private let store: EngineStore
  private let sensor: LocationSensor
  private let trail: TrailBuffer
  private let writer: FirestoreWriter
  private let stillAlarm = Alarm()
  private let placeAlarm = Alarm()
  private let dwellActivity = BackgroundActivity()

  private var config: EngineConfig?
  private var stillness = StillnessDetector()
  private var presence = PlacePresence()
  private var motion: MotionLabel = .unknown
  private var lastFix: Fix?
  private var lastRecorded: Fix?
  private var plannedAround: Fix?
  private var lastFlushRequest: Date

  init(clock: Clock = SystemClock(), store: EngineStore = EngineStore(), trailFile: URL = TrailBuffer.defaultFile()) {
    self.clock = clock
    self.store = store
    sensor = LocationSensor()
    trail = TrailBuffer(file: trailFile)
    writer = FirestoreWriter(store: store, trail: trail, clock: clock)
    permissions = PermissionDesk(sensor: sensor, store: store)
    lastFlushRequest = clock.now
    super.init()
    sensor.delegate = self
    writer.delegate = self
  }

  func launch() {
    LeaseRefresh.register { [weak self] finish in
      guard let self else { return finish(false) }
      self.renewLease(finish)
    }
    NotificationCenter.default.addObserver(
      self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil
    )
    NotificationCenter.default.addObserver(
      self, selector: #selector(protectedDataAvailable),
      name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil
    )
    resume()
  }

  func flutterStarted() { writer.pump() }

  var status: [String: Any] {
    [
      "running": config != nil,
      "householdId": config?.householdId ?? NSNull(),
      "memberId": config?.memberId ?? NSNull(),
      "lastStopReason": store.lastStopReason?.rawValue ?? NSNull(),
    ]
  }

  func start(_ new: EngineConfig) throws {
    switch sensor.authorization {
    case .authorizedAlways: break
    case .authorizedWhenInUse: throw StartRefusal.noBackground
    default: throw StartRefusal.noPermission
    }
    store.lastStopReason = nil
    if let current = config, current.isSameSession(as: new) {
      if store.uid == nil { store.uid = writer.signedInUid() }
      apply(new)
      writer.requestLive()
    } else {
      if let previous = config { writer.retireLive(of: previous) }
      teardown(signOut: false)
      store.uid = writer.signedInUid()
      activate(new, fresh: true)
    }
    onEvent?(["event": "started"])
  }

  func stop(_ reason: StopReason? = nil, then done: (() -> Void)? = nil) {
    guard config != nil else {
      done?()
      return
    }
    config = nil
    store.config = nil
    sensor.stopAll()
    stillAlarm.cancel()
    placeAlarm.cancel()
    dwellActivity.hold(false)
    LeaseRefresh.cancel()
    writer.dropLive()
    if let reason {
      store.lastStopReason = reason
      onEvent?(["event": "stopped", "reason": reason.rawValue])
    }
    let finish = { [weak self] in
      if let self, self.config == nil { self.teardown(signOut: true) }
      done?()
    }
    if reason == .refused || reason == .signedOut {
      finish()
    } else {
      writer.drainTrail(within: Self.stopDrain, finish)
    }
  }

  func setForeground(_ foreground: Bool) {
    guard var updated = config else { return }
    updated.foreground = foreground
    apply(updated)
  }

  func setPlaces(_ places: [FamilyPlace]) {
    guard var updated = config else { return }
    updated.places = places
    apply(updated)
  }

  private var isStill: Bool { store.stillCentre != nil }

  private var currentMotion: MotionLabel { isStill ? .still : motion }

  private func resume() {
    guard !Self.underTest, config == nil, let saved = store.config else { return }
    activate(saved, fresh: false)
  }

  private func activate(_ config: EngineConfig, fresh: Bool) {
    self.config = config
    store.config = config
    if fresh {
      writer.markFresh()
    } else {
      trail.reload()
      presence = store.presence
      lastFix = store.lastFix
      writer.restore()
    }
    sensor.watch()
    if let centre = store.stillCentre {
      sensor.holdStill(around: centre)
    } else {
      beginMoving()
    }
    planRegions(force: true)
    LeaseRefresh.schedule()
    writer.begin(config)
    writer.requestPlaces()
    if fresh { writer.requestLive() }
    guard sensor.authorization == .authorizedAlways else { return stop(.permissionRevoked) }
  }

  private func apply(_ updated: EngineConfig) {
    let placesChanged = updated.places != config?.places
    config = updated
    store.config = updated
    if !isStill { sensor.setForeground(updated.foreground) }
    if placesChanged {
      let ids = Set(updated.places.map(\.id))
      presence.keep(only: ids)
      store.presence = presence
      writer.pruneEvents(keeping: ids)
      planRegions(force: true)
    }
    writer.begin(updated)
  }

  private func teardown(signOut: Bool) {
    writer.reset(signOut: signOut)
    trail.clear()
    store.clearSession()
    resetSession()
  }

  private func resetSession() {
    presence = PlacePresence()
    stillness = StillnessDetector()
    motion = .unknown
    lastFix = nil
    lastRecorded = nil
    plannedAround = nil
    lastFlushRequest = clock.now
  }

  private func beginMoving() {
    store.stillCentre = nil
    sensor.releaseStill()
    sensor.track(foreground: config?.foreground ?? false)
    stillness.reset(anchor: lastFix, at: clock.now)
    armStillAlarm()
  }

  private func becomeStill() {
    guard let fix = lastFix, !isStill else { return }
    store.stillCentre = fix
    stillAlarm.cancel()
    sensor.stopTracking()
    sensor.holdStill(around: fix)
    writer.requestLive()
    requestFlush()
    checkPlaces()
  }

  private func leaveStill() {
    guard isStill else { return }
    beginMoving()
    writer.requestLive()
  }

  private func armStillAlarm() {
    let now = clock.now
    guard !stillness.isStill(at: now) else { return becomeStill() }
    guard let at = stillness.alarm(at: now) else { return stillAlarm.cancel() }
    stillAlarm.set(at: at, now: now) { [weak self] in
      guard let self, !self.isStill, self.config != nil else { return }
      self.armStillAlarm()
    }
  }

  private func record(_ fix: Fix) {
    let now = clock.now
    if TrailPolicy.shouldRecord(fix, after: lastRecorded) {
      trail.append(TrailPoint(fix))
      lastRecorded = fix
      if TrailPolicy.shouldFlush(buffered: trail.points.count, lastFlush: lastFlushRequest, now: now) {
        requestFlush()
      }
    }
    let foreground = config?.foreground ?? false
    if LivePolicy.shouldWrite(fix, motion: currentMotion, foreground: foreground, since: writer.lastLive, now: now) {
      writer.requestLive()
    }
    let anchor = stillness.anchor
    stillness.observe(fix, at: now)
    if stillness.isStill(at: now) {
      becomeStill()
    } else if stillness.anchor != anchor {
      armStillAlarm()
    }
  }

  private func requestFlush() {
    lastFlushRequest = clock.now
    writer.requestTrailFlush()
  }

  private func woke() {
    if LivePolicy.needsRenewal(since: writer.lastLive, now: clock.now) { writer.requestLive() }
    checkPlaces()
    writer.pump()
  }

  private func planRegions(force: Bool) {
    guard let config else { return }
    if !force, let fix = lastFix, !RegionPlanner.needsReplan(plannedAround: plannedAround, now: fix) { return }
    plannedAround = lastFix
    sensor.monitor(RegionPlanner.places(config.places, nearest: lastFix))
  }

  private func checkPlaces() {
    let now = clock.now
    let due = presence.idsToCheck(at: now)
    due.forEach(sensor.checkPlace)
    if due.contains(where: presence.awaitingDwell.contains) { sensor.requestFix() }
    dwellActivity.hold(!presence.awaitingDwell.isEmpty)
    guard let next = presence.nextCheck, next > now else { return placeAlarm.cancel() }
    placeAlarm.set(at: next, now: now) { [weak self] in self?.checkPlaces() }
  }

  private func confirmDwell(with fix: Fix) {
    guard let config else { return }
    for id in presence.awaitingDwell {
      guard let place = config.place(id), fix.isInside(place) else { continue }
      observe(place: id, inside: true)
    }
  }

  private func observe(place id: String, inside: Bool) {
    let now = clock.now
    emit(presence.observe(id, inside: inside, at: now), crossedAt: now)
  }

  private func emit(_ transition: PlaceTransition?, crossedAt: Date) {
    store.presence = presence
    guard let transition else { return }
    writer.enqueue(PlaceEvent(transition, at: crossedAt))
  }

  private func renewLease(_ finish: @escaping (Bool) -> Void) {
    resume()
    guard config != nil else { return finish(true) }
    LeaseRefresh.schedule()
    writer.requestPlaces()
    writer.requestLive(then: finish)
  }

  @objc private func didEnterBackground() {
    guard config != nil else { return }
    requestFlush()
  }

  @objc private func protectedDataAvailable() {
    // Auth reloads its keychain user on its own queue from this same notification; the next turn of the
    // main queue reads it after that reload.
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if self.config == nil { self.resume() } else { self.writer.pump() }
    }
  }
}

extension LocationEngine: LocationSensorDelegate {
  func sensor(didUpdate fix: Fix) {
    resume()
    guard config != nil else { return }
    guard FixFilter.isUsable(fix, at: clock.now, reducedAccuracy: sensor.isAccuracyReduced) else { return woke() }
    guard !isStill else {
      confirmDwell(with: fix)
      return woke()
    }
    lastFix = fix
    store.lastFix = fix
    confirmDwell(with: fix)
    planRegions(force: false)
    record(fix)
    woke()
  }

  func sensorDidPause() {
    resume()
    guard config != nil else { return }
    if lastFix == nil {
      sensor.track(foreground: config?.foreground ?? false)
    } else {
      becomeStill()
    }
  }

  func sensorDidLeaveStillRegion() {
    resume()
    guard config != nil else { return }
    leaveStill()
    woke()
  }

  func sensorDidVisit(departed: Bool, at fix: Fix) {
    resume()
    guard let config else { return }
    if departed {
      leaveStill()
    } else {
      for place in config.places where fix.isInside(place) {
        emit(presence.visit(place.id, at: clock.now), crossedAt: fix.timestamp)
      }
    }
    woke()
  }

  func sensor(place id: String, inside: Bool) {
    resume()
    guard config?.place(id) != nil else { return }
    observe(place: id, inside: inside)
    woke()
  }

  func sensor(didChangeMotion motion: MotionLabel) {
    resume()
    guard let config, !isStill, motion != self.motion else { return }
    self.motion = motion
    guard config.foreground, let fix = lastFix else { return }
    if LivePolicy.shouldWrite(fix, motion: motion, foreground: true, since: writer.lastLive, now: clock.now) {
      writer.requestLive()
    }
  }

  func sensor(didChangeAuthorization status: CLAuthorizationStatus) {
    resume()
    permissions.authorizationChanged()
    guard config != nil, status != .authorizedAlways else { return }
    stop(.permissionRevoked)
  }
}

extension LocationEngine: FirestoreWriterDelegate {
  func writerSnapshot() -> LiveSnapshot? {
    guard let lastFix else { return nil }
    return LiveSnapshot(fix: lastFix, motion: currentMotion, battery: .current())
  }

  func writerRefused() {
    DispatchQueue.main.async { self.stop(.refused) }
  }

  func writerSignedOut() {
    DispatchQueue.main.async { self.stop(.signedOut) }
  }

  func writerFetched(places: [FamilyPlace]) {
    guard let config, places != config.places else { return }
    setPlaces(places)
  }
}
