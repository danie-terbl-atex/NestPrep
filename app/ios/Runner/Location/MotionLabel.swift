import CoreMotion

enum MotionLabel: String, Codable {
  case still, onFoot, cycling, driving, unknown

  init(_ activity: CMMotionActivity) {
    if activity.automotive {
      self = .driving
    } else if activity.cycling {
      self = .cycling
    } else if activity.walking || activity.running {
      self = .onFoot
    } else if activity.stationary {
      self = .still
    } else {
      self = .unknown
    }
  }
}
