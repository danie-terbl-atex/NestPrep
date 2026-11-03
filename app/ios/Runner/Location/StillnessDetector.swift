import Foundation

struct StillnessDetector {
  static let window: TimeInterval = 5 * 60
  static let radius: Double = 50

  private(set) var anchor: Fix?
  private(set) var since: Date?

  mutating func reset(anchor: Fix?, at now: Date) {
    self.anchor = anchor
    since = now
  }

  mutating func observe(_ fix: Fix, at now: Date) {
    if let anchor, fix.distance(to: anchor) < Self.radius { return }
    anchor = fix
    since = now
  }

  var deadline: Date? { since?.addingTimeInterval(Self.window) }

  func alarm(at now: Date) -> Date? {
    guard anchor != nil, let deadline, deadline > now else { return nil }
    return deadline
  }

  func isStill(at now: Date) -> Bool {
    guard anchor != nil, let deadline else { return false }
    return now >= deadline
  }
}
