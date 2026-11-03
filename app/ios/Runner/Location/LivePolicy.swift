import Foundation

struct LiveWrite: Codable, Equatable {
  let fix: Fix
  let motion: MotionLabel
  let completedAt: Date
}

enum LivePolicy {
  static let spacing: TimeInterval = 12
  static let renewal: TimeInterval = 60 * 60

  static func shouldWrite(
    _ fix: Fix, motion: MotionLabel, foreground: Bool, since last: LiveWrite?, now: Date
  ) -> Bool {
    guard let last else { return true }
    let elapsed = now.timeIntervalSince(last.completedAt)
    let moved = fix.distance(to: last.fix)
    if foreground {
      return elapsed >= 20 && (moved >= 25 || motion != last.motion)
    }
    return elapsed >= 120 || (moved >= 250 && elapsed >= 15)
  }

  static func needsRenewal(since last: LiveWrite?, now: Date) -> Bool {
    guard let last else { return true }
    return now.timeIntervalSince(last.completedAt) >= renewal
  }
}
