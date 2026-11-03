import Foundation

enum TrailPolicy {
  static let minimumAccuracy: Double = 100
  static let spacingMetres: Double = 30
  static let spacingTime: TimeInterval = 5 * 60
  static let shortestGap: TimeInterval = 15
  static let flushPoints = 30
  static let flushInterval: TimeInterval = 15 * 60

  static func shouldRecord(_ fix: Fix, after last: Fix?) -> Bool {
    guard fix.accuracy >= 0, fix.accuracy <= minimumAccuracy else { return false }
    guard let last else { return true }
    let gap = fix.timestamp.timeIntervalSince(last.timestamp)
    guard gap >= shortestGap else { return false }
    return fix.distance(to: last) >= spacingMetres || gap >= spacingTime
  }

  static func shouldFlush(buffered: Int, lastFlush: Date, now: Date) -> Bool {
    buffered >= flushPoints || now.timeIntervalSince(lastFlush) >= flushInterval
  }
}
