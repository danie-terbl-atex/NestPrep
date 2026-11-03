import Foundation

struct TrailLedger: Codable, Equatable {
  static let daysKept = 3

  var lastWrite: [String: Date] = [:]
  var sent: [String: Int] = [:]

  mutating func record(_ batch: TrailBatch, at now: Date) {
    lastWrite[batch.day] = now
    sent[batch.day, default: 0] += batch.points.count
    let kept = Set(sent.keys.sorted().suffix(Self.daysKept))
    sent = sent.filter { kept.contains($0.key) }
    lastWrite = lastWrite.filter { kept.contains($0.key) }
  }
}

struct TrailBatch: Equatable {
  let day: String
  let points: [TrailPoint]
}

struct TrailPlan: Equatable {
  var batch: TrailBatch?
  var dropped: [TrailPoint] = []
  var retryAt: Date?
}

enum TrailPlanner {
  static let pointsPerWrite = 120
  static let pointsPerDay = 3_000
  static let docSpacing: TimeInterval = 30

  static func plan(_ points: [TrailPoint], zone: TimeZone, ledger: TrailLedger, now: Date) -> TrailPlan {
    var days: [String] = []
    var byDay: [String: [TrailPoint]] = [:]
    for point in points {
      let day = point.day(in: zone)
      if byDay[day] == nil { days.append(day) }
      byDay[day, default: []].append(point)
    }

    var plan = TrailPlan()
    for day in days {
      let dayPoints = byDay[day] ?? []
      let room = max(0, pointsPerDay - ledger.sent[day, default: 0])
      plan.dropped += dayPoints.dropFirst(room)
      let writable = dayPoints.prefix(room)
      guard !writable.isEmpty else { continue }
      if let last = ledger.lastWrite[day], now < last.addingTimeInterval(docSpacing) {
        let due = last.addingTimeInterval(docSpacing)
        plan.retryAt = min(plan.retryAt ?? due, due)
        continue
      }
      if plan.batch == nil {
        plan.batch = TrailBatch(day: day, points: Array(writable.prefix(pointsPerWrite)))
      }
    }
    return plan
  }
}
