import Foundation

enum FixFilter {
  static let maxAge: TimeInterval = 60
  static let maxAccuracy: Double = 100

  static func isUsable(_ fix: Fix, at now: Date, reducedAccuracy: Bool) -> Bool {
    guard fix.accuracy >= 0, now.timeIntervalSince(fix.timestamp) <= maxAge else { return false }
    return reducedAccuracy || fix.accuracy <= maxAccuracy
  }
}
