import CoreLocation
import CoreMotion

enum PermissionMap {
  static func location(_ status: CLAuthorizationStatus, servicesEnabled: Bool, reducedAccuracy: Bool) -> String {
    guard servicesEnabled else { return "off" }
    switch status {
    case .authorizedAlways: return reducedAccuracy ? "whileInUse" : "always"
    case .authorizedWhenInUse: return "whileInUse"
    case .denied, .restricted: return "deniedForever"
    default: return "denied"
    }
  }

  static func motion(_ status: CMAuthorizationStatus, available: Bool) -> String {
    guard available else { return "notNeeded" }
    return status == .authorized ? "granted" : "denied"
  }
}
