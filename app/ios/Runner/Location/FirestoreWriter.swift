import FirebaseFirestore
import os

protocol FirestoreWriterDelegate: AnyObject {
  func writerSnapshot() -> LiveSnapshot?
  func writerRefused()
  func writerSignedOut()
  func writerFetched(places: [FamilyPlace])
}

final class FirestoreWriter {
  weak var delegate: FirestoreWriterDelegate?

  private static let log = Logger(subsystem: "io.nullstate.nestprep", category: "location")
  private static let retireTimeout: TimeInterval = 5

  private let store: EngineStore
  private let trail: TrailBuffer
  private let clock: Clock
  private let activity = BackgroundActivity()
  private let alarm = Alarm()
  private let link = FirebaseLink()

  private var config: EngineConfig?
  private var paths: DocumentPaths?
  private var live: WriteGate
  private var days = WriteGate(lane: .trail, spacing: 0)
  private var events = WriteGate(lane: .event, spacing: 0)
  private var liveWanted = false
  private var trailWanted = false
  private var placesWanted = false
  private var placesInFlight = false
  private var retiring = false
  private var generation = 0
  private var liveWaiters: [(Bool) -> Void] = []
  private var drainDeadline: Date?
  private var drainDone: Once?

  private(set) var lastLive: LiveWrite?

  init(store: EngineStore, trail: TrailBuffer, clock: Clock) {
    self.store = store
    self.trail = trail
    self.clock = clock
    lastLive = store.lastLive
    live = WriteGate(lane: .live, spacing: LivePolicy.spacing, lastCompletion: lastLive?.completedAt)
  }

  func signedInUid() -> String? { link.signedInUid() }

  func restore() {
    lastLive = store.lastLive
    live = WriteGate(lane: .live, spacing: LivePolicy.spacing, lastCompletion: lastLive?.completedAt)
  }

  func markFresh() {
    live = WriteGate(lane: .live, spacing: LivePolicy.spacing, fresh: true)
  }

  func begin(_ config: EngineConfig) {
    self.config = config
    paths = DocumentPaths(config)
    pump()
  }

  func requestLive(then done: ((Bool) -> Void)? = nil) {
    liveWanted = true
    if let done { liveWaiters.append(done) }
    pump()
  }

  func dropLive() {
    liveWanted = false
  }

  func requestTrailFlush() {
    trailWanted = true
    pump()
  }

  func requestPlaces() {
    placesWanted = true
    pump()
  }

  func enqueue(_ event: PlaceEvent) {
    store.events.append(event)
    pump()
  }

  func pruneEvents(keeping placeIds: Set<String>) {
    store.events.removeAll { !placeIds.contains($0.placeId) }
  }

  func drainTrail(within timeout: TimeInterval, _ done: @escaping () -> Void) {
    let once = Once(done)
    drainDone = once
    drainDeadline = clock.now.addingTimeInterval(timeout)
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { once.run() }
    requestTrailFlush()
    if paths == nil { finishDrain() }
  }

  func retireLive(of config: EngineConfig, then done: @escaping () -> Void = {}) {
    guard let firestore = link.current(config) else { return done() }
    let once = Once(done)
    firestore.document(DocumentPaths(config).live).delete { _ in once.run() }
    DispatchQueue.main.asyncAfter(deadline: .now() + Self.retireTimeout) { once.run() }
  }

  func reset(signOut: Bool) {
    generation += 1
    if signOut { link.signOut() }
    config = nil
    paths = nil
    liveWanted = false
    trailWanted = false
    placesWanted = false
    placesInFlight = false
    retiring = false
    lastLive = nil
    live = WriteGate(lane: .live, spacing: LivePolicy.spacing)
    days = WriteGate(lane: .trail, spacing: 0)
    events = WriteGate(lane: .event, spacing: 0)
    alarm.cancel()
    let waiters = liveWaiters
    liveWaiters = []
    waiters.forEach { $0(false) }
    finishDrain()
    activity.hold(false)
  }

  func pump() {
    alarm.cancel()
    defer { activity.hold(isBusy) }
    guard let config, let paths, !retiring else { return }
    let firestore: Firestore
    switch link.session(config, uid: store.uid, changed: { [weak self] in self?.pump() }) {
    case .waiting:
      return
    case .signedOut:
      retire(config)
      return
    case .ready(let connected):
      firestore = connected
    }
    let now = clock.now
    if placesWanted, !placesInFlight { fetchPlaces(firestore, paths) }
    let retries = [
      liveWanted ? sendLive(firestore, paths, now: now) : nil,
      trailWanted ? sendTrail(firestore, paths, config.zone, now: now) : nil,
      sendEvent(firestore, paths, now: now),
    ].compactMap { $0 }
    if let next = retries.min() {
      alarm.set(at: next, now: now) { [weak self] in self?.pump() }
    }
  }

  private var isBusy: Bool {
    guard paths != nil else { return false }
    return live.inFlight || days.inFlight || events.inFlight || liveWanted || !store.events.isEmpty
      || drainDone != nil || retiring
  }

  private func retire(_ config: EngineConfig) {
    retiring = true
    retireLive(of: config) { [weak self] in
      guard let self, self.retiring else { return }
      self.link.signOut()
      self.delegate?.writerSignedOut()
    }
  }

  private func fetchPlaces(_ firestore: Firestore, _ paths: DocumentPaths) {
    placesWanted = false
    placesInFlight = true
    let generation = generation
    firestore.collection(paths.places).getDocuments { [weak self] snapshot, _ in
      guard let self, generation == self.generation else { return }
      self.placesInFlight = false
      guard let snapshot else { return }
      let documents = snapshot.documents.map { (id: $0.documentID, data: $0.data()) }
      self.delegate?.writerFetched(places: FamilyPlace.list(fromDocuments: documents))
    }
  }

  private func sendLive(_ firestore: Firestore, _ paths: DocumentPaths, now: Date) -> Date? {
    guard let earliest = live.earliestSend else { return nil }
    guard earliest <= now else { return earliest }
    guard let snapshot = delegate?.writerSnapshot() else { return nil }
    liveWanted = false
    live.begin(at: now)
    let generation = generation
    firestore.document(paths.live).setData(Payloads.live(snapshot, now: now)) { [weak self] error in
      guard let self, generation == self.generation else { return }
      self.liveFinished(snapshot, error: error)
    }
    return nil
  }

  private func liveFinished(_ snapshot: LiveSnapshot, error: Error?) {
    let now = clock.now
    if let error {
      switch live.fail(WriteFailure(error), at: now) {
      case .refused: return refused()
      case .retry: liveWanted = true
      case .settled, .dropped: break
      }
    } else {
      live.succeed(at: now)
      lastLive = LiveWrite(fix: snapshot.fix, motion: snapshot.motion, completedAt: now)
      store.lastLive = lastLive
      let waiters = liveWaiters
      liveWaiters = []
      waiters.forEach { $0(true) }
    }
    pump()
  }

  private func sendTrail(_ firestore: Firestore, _ paths: DocumentPaths, _ zone: TimeZone, now: Date) -> Date? {
    guard let earliest = days.earliestSend else { return nil }
    guard earliest <= now else { return earliest }
    let plan = TrailPlanner.plan(trail.points, zone: zone, ledger: store.ledger, now: now)
    if !plan.dropped.isEmpty {
      Self.log.notice("dropped \(plan.dropped.count) trail points over the day cap")
      trail.remove(plan.dropped)
    }
    guard let batch = plan.batch else {
      if plan.retryAt == nil { trailWanted = false }
      if let deadline = drainDeadline, (plan.retryAt ?? .distantFuture) > deadline { finishDrain() }
      return plan.retryAt
    }
    days.begin(at: now)
    let generation = generation
    firestore.document(paths.day(batch.day))
      .setData(Payloads.trail(batch.points, now: now), merge: true) { [weak self] error in
        guard let self, generation == self.generation else { return }
        self.trailFinished(batch, error: error)
      }
    return nil
  }

  private func trailFinished(_ batch: TrailBatch, error: Error?) {
    let now = clock.now
    if let error {
      switch days.fail(WriteFailure(error), at: now) {
      case .dropped:
        Self.log.error("trail day \(batch.day, privacy: .public) refused; dropped \(batch.points.count) points")
        trail.remove(batch.points)
      case .retry, .settled, .refused:
        if drainDeadline != nil { finishDrain() }
      }
    } else {
      days.succeed(at: now)
      trail.remove(batch.points)
      var ledger = store.ledger
      ledger.record(batch, at: now)
      store.ledger = ledger
    }
    pump()
  }

  private func sendEvent(_ firestore: Firestore, _ paths: DocumentPaths, now: Date) -> Date? {
    let stale = store.events.filter { $0.isStale(at: now) }
    if !stale.isEmpty {
      Self.log.notice("dropped \(stale.count) place crossings older than fifteen minutes")
      store.events.removeAll { $0.isStale(at: now) }
    }
    guard let event = store.events.first, let earliest = events.earliestSend else { return nil }
    guard earliest <= now else { return earliest }
    events.begin(at: now)
    let generation = generation
    firestore.document(paths.event(event.id)).setData(Payloads.event(event, now: now)) {
      [weak self] error in
      guard let self, generation == self.generation else { return }
      self.eventFinished(event, error: error)
    }
    return nil
  }

  private func eventFinished(_ event: PlaceEvent, error: Error?) {
    let now = clock.now
    if let error {
      switch events.fail(WriteFailure(error), at: now) {
      case .dropped:
        Self.log.error("place event for \(event.placeId, privacy: .public) refused; dropped")
        store.events.removeAll { $0.id == event.id }
      case .settled:
        store.events.removeAll { $0.id == event.id }
      case .retry, .refused:
        break
      }
    } else {
      events.succeed(at: now)
      store.events.removeAll { $0.id == event.id }
    }
    pump()
  }

  private func refused() {
    activity.hold(false)
    delegate?.writerRefused()
  }

  private func finishDrain() {
    let done = drainDone
    drainDone = nil
    drainDeadline = nil
    done?.run()
  }
}
