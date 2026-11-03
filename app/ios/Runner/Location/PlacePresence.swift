import Foundation

enum PlaceTransition: Equatable {
  case arrive(String)
  case leave(String)
}

struct PlacePresence: Codable, Equatable {
  static let dwell: TimeInterval = 60
  static let exitGrace: TimeInterval = 3 * 60

  private(set) var entered: [String: Date] = [:]
  private(set) var arrived: [String: Date] = [:]
  private(set) var leaving: [String: Date] = [:]

  mutating func observe(_ id: String, inside: Bool, at now: Date) -> PlaceTransition? {
    inside ? observeInside(id, at: now) : observeOutside(id, at: now)
  }

  var awaitingDwell: [String] { Array(entered.keys) }

  mutating func visit(_ id: String, at now: Date) -> PlaceTransition? {
    leaving[id] = nil
    guard arrived[id] == nil else { return nil }
    entered[id] = nil
    arrived[id] = now
    return .arrive(id)
  }

  func idsToCheck(at now: Date) -> [String] {
    let dwelt = entered.filter { now >= $0.value.addingTimeInterval(Self.dwell) }.keys
    let left = leaving.filter { now >= $0.value }.keys
    return Array(dwelt) + Array(left)
  }

  var nextCheck: Date? {
    (entered.values.map { $0.addingTimeInterval(Self.dwell) } + leaving.values).min()
  }

  mutating func keep(only ids: Set<String>) {
    entered = entered.filter { ids.contains($0.key) }
    arrived = arrived.filter { ids.contains($0.key) }
    leaving = leaving.filter { ids.contains($0.key) }
  }

  private mutating func observeInside(_ id: String, at now: Date) -> PlaceTransition? {
    if arrived[id] != nil {
      leaving[id] = nil
      return nil
    }
    guard let since = entered[id] else {
      entered[id] = now
      return nil
    }
    guard now >= since.addingTimeInterval(Self.dwell) else { return nil }
    entered[id] = nil
    arrived[id] = now
    return .arrive(id)
  }

  private mutating func observeOutside(_ id: String, at now: Date) -> PlaceTransition? {
    entered[id] = nil
    guard let arrivedAt = arrived[id] else { return nil }
    let settled = arrivedAt.addingTimeInterval(Self.exitGrace)
    guard now >= settled else {
      leaving[id] = settled
      return nil
    }
    arrived[id] = nil
    leaving[id] = nil
    return .leave(id)
  }
}
