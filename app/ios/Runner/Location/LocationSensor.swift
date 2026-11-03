import CoreLocation
import CoreMotion

protocol LocationSensorDelegate: AnyObject {
  func sensor(didUpdate fix: Fix)
  func sensorDidPause()
  func sensorDidLeaveStillRegion()
  func sensorDidVisit(departed: Bool, at fix: Fix)
  func sensor(place id: String, inside: Bool)
  func sensor(didChangeMotion motion: MotionLabel)
  func sensor(didChangeAuthorization status: CLAuthorizationStatus)
}

final class LocationSensor: NSObject, CLLocationManagerDelegate {
  static let stillRadius: CLLocationDistance = 150
  private static let stillId = "io.nullstate.nestprep.still"
  private static let placePrefix = "io.nullstate.nestprep.place."

  weak var delegate: LocationSensorDelegate?
  private let manager = CLLocationManager()
  private let activity = CMMotionActivityManager()

  override init() {
    super.init()
    manager.delegate = self
    manager.activityType = .other
    manager.pausesLocationUpdatesAutomatically = true
    manager.showsBackgroundLocationIndicator = true
  }

  var authorization: CLAuthorizationStatus { manager.authorizationStatus }

  var isAccuracyReduced: Bool { manager.accuracyAuthorization == .reducedAccuracy }

  func requestFix() { manager.requestLocation() }

  func requestAlways() { manager.requestAlwaysAuthorization() }

  func watch() {
    manager.allowsBackgroundLocationUpdates = true
    manager.startMonitoringSignificantLocationChanges()
    manager.startMonitoringVisits()
  }

  func track(foreground: Bool) {
    setForeground(foreground)
    manager.distanceFilter = 25
    manager.startUpdatingLocation()
    guard CMMotionActivityManager.isActivityAvailable(),
      CMMotionActivityManager.authorizationStatus() == .authorized
    else { return }
    activity.startActivityUpdates(to: .main) { [weak self] activity in
      guard let activity else { return }
      let motion = MotionLabel(activity)
      if motion != .unknown { self?.delegate?.sensor(didChangeMotion: motion) }
    }
  }

  func setForeground(_ foreground: Bool) {
    manager.desiredAccuracy = foreground ? kCLLocationAccuracyNearestTenMeters : kCLLocationAccuracyHundredMeters
  }

  func stopTracking() {
    manager.stopUpdatingLocation()
    activity.stopActivityUpdates()
  }

  func holdStill(around fix: Fix) {
    let region = CLCircularRegion(center: fix.coordinate, radius: Self.stillRadius, identifier: Self.stillId)
    region.notifyOnEntry = false
    region.notifyOnExit = true
    manager.startMonitoring(for: region)
  }

  func releaseStill() {
    for region in manager.monitoredRegions where region.identifier == Self.stillId {
      manager.stopMonitoring(for: region)
    }
  }

  func monitor(_ places: [FamilyPlace]) {
    let wanted = Dictionary(places.map { (Self.placePrefix + $0.id, $0) }, uniquingKeysWith: { _, last in last })
    for region in manager.monitoredRegions where region.identifier.hasPrefix(Self.placePrefix) {
      guard let region = region as? CLCircularRegion, let place = wanted[region.identifier],
        region.center.latitude == place.latitude, region.center.longitude == place.longitude,
        region.radius == place.radiusMetres
      else {
        manager.stopMonitoring(for: region)
        continue
      }
    }
    let monitored = Set(manager.monitoredRegions.map(\.identifier))
    for (identifier, place) in wanted where !monitored.contains(identifier) {
      let radius = min(place.radiusMetres, manager.maximumRegionMonitoringDistance)
      let centre = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
      manager.startMonitoring(for: CLCircularRegion(center: centre, radius: radius, identifier: identifier))
    }
  }

  func checkPlace(_ id: String) {
    for region in manager.monitoredRegions where region.identifier == Self.placePrefix + id {
      manager.requestState(for: region)
    }
  }

  func stopAll() {
    stopTracking()
    manager.stopMonitoringSignificantLocationChanges()
    manager.stopMonitoringVisits()
    for region in manager.monitoredRegions
    where region.identifier == Self.stillId || region.identifier.hasPrefix(Self.placePrefix) {
      manager.stopMonitoring(for: region)
    }
    manager.allowsBackgroundLocationUpdates = false
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    for location in locations where location.horizontalAccuracy >= 0 {
      delegate?.sensor(didUpdate: Fix(location))
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

  func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
    delegate?.sensorDidPause()
  }

  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    guard let id = placeId(region) else { return }
    delegate?.sensor(place: id, inside: true)
  }

  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    if region.identifier == Self.stillId {
      delegate?.sensorDidLeaveStillRegion()
    } else if let id = placeId(region) {
      delegate?.sensor(place: id, inside: false)
    }
  }

  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    guard let id = placeId(region), state != .unknown else { return }
    delegate?.sensor(place: id, inside: state == .inside)
  }

  func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
    guard placeId(region) != nil else { return }
    manager.requestState(for: region)
  }

  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {}

  func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
    let fix = Fix(
      latitude: visit.coordinate.latitude,
      longitude: visit.coordinate.longitude,
      accuracy: visit.horizontalAccuracy,
      timestamp: visit.arrivalDate
    )
    delegate?.sensorDidVisit(departed: visit.departureDate != .distantFuture, at: fix)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    delegate?.sensor(didChangeAuthorization: manager.authorizationStatus)
  }

  private func placeId(_ region: CLRegion) -> String? {
    guard region.identifier.hasPrefix(Self.placePrefix) else { return nil }
    return String(region.identifier.dropFirst(Self.placePrefix.count))
  }
}
