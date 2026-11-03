import CoreLocation
import CoreMotion
import UIKit

final class PermissionDesk {
  typealias Reply = ([String: String]) -> Void

  private static let alwaysTimeout: TimeInterval = 30

  private let sensor: LocationSensor
  private let store: EngineStore
  private let motion = CMMotionActivityManager()
  private let timeout = Alarm()
  private var waiting: [Reply] = []
  private var activeObserver: NSObjectProtocol?

  init(sensor: LocationSensor, store: EngineStore) {
    self.sensor = sensor
    self.store = store
  }

  func current(_ reply: @escaping Reply) {
    DispatchQueue.global(qos: .userInitiated).async {
      let enabled = CLLocationManager.locationServicesEnabled()
      DispatchQueue.main.async {
        reply([
          "location": PermissionMap.location(
            self.sensor.authorization, servicesEnabled: enabled, reducedAccuracy: self.sensor.isAccuracyReduced
          ),
          "motion": PermissionMap.motion(
            CMMotionActivityManager.authorizationStatus(),
            available: CMMotionActivityManager.isActivityAvailable()
          ),
        ])
      }
    }
  }

  func requestAlways(_ reply: @escaping Reply) {
    let status = sensor.authorization
    // iOS shows the upgrade-to-Always prompt once per install and then ignores the request without a callback.
    let upgrading = status == .authorizedWhenInUse && !store.askedAlways
    guard status == .notDetermined || upgrading else { return current(reply) }
    if upgrading { store.askedAlways = true }
    waiting.append(reply)
    timeout.set(at: Date(timeIntervalSinceNow: Self.alwaysTimeout), now: Date()) { [weak self] in self?.settle() }
    if activeObserver == nil {
      // "Keep While Using" leaves the status unchanged, so no authorization callback arrives.
      activeObserver = NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
      ) { [weak self] _ in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self?.settle() }
      }
    }
    sensor.requestAlways()
  }

  func authorizationChanged() { settle() }

  func requestMotion(_ reply: @escaping Reply) {
    guard CMMotionActivityManager.isActivityAvailable(),
      CMMotionActivityManager.authorizationStatus() == .notDetermined
    else { return current(reply) }
    let now = Date()
    motion.queryActivityStarting(from: now.addingTimeInterval(-60), to: now, to: .main) { [weak self] _, _ in
      self?.current(reply)
    }
  }

  private func settle() {
    guard !waiting.isEmpty else { return }
    let replies = waiting
    waiting = []
    timeout.cancel()
    if let activeObserver {
      NotificationCenter.default.removeObserver(activeObserver)
      self.activeObserver = nil
    }
    replies.forEach(current)
  }
}
