import Foundation

enum WriteLane {
  case live, trail, event
}

enum WriteFailure: Equatable {
  case permissionDenied, alreadyExists, other
}

enum WriteVerdict: Equatable {
  case retry(at: Date)
  case settled
  case dropped
  case refused
}

struct WriteGate {
  static let deniedRetry: TimeInterval = 30
  static let firstBackoff: TimeInterval = 30
  static let longestBackoff: TimeInterval = 15 * 60
  static let staleAfter: TimeInterval = 5 * 60

  let lane: WriteLane
  let spacing: TimeInterval
  private(set) var inFlight = false
  private(set) var sentAt: Date?
  private(set) var lastCompletion: Date?
  private(set) var retryAt: Date?
  private var denials = 0
  private var failures = 0
  private var forgivesPace: Bool

  init(lane: WriteLane, spacing: TimeInterval, lastCompletion: Date? = nil, fresh: Bool = false) {
    self.lane = lane
    self.spacing = spacing
    self.lastCompletion = lastCompletion
    forgivesPace = fresh
  }

  var earliestSend: Date? {
    guard !inFlight else { return nil }
    let paced = lastCompletion?.addingTimeInterval(spacing) ?? .distantPast
    return max(paced, retryAt ?? .distantPast)
  }

  func canSend(at now: Date) -> Bool { earliestSend.map { $0 <= now } ?? false }

  mutating func begin(at now: Date) {
    inFlight = true
    sentAt = now
  }

  mutating func succeed(at now: Date) {
    inFlight = false
    lastCompletion = now
    retryAt = nil
    denials = 0
    failures = 0
    forgivesPace = false
  }

  mutating func fail(_ failure: WriteFailure, at now: Date) -> WriteVerdict {
    inFlight = false
    let queued = sentAt.map { now.timeIntervalSince($0) } ?? 0
    switch failure {
    case .alreadyExists where lane == .event:
      succeed(at: now)
      return .settled
    case .permissionDenied where queued > Self.staleAfter:
      return retry(after: 0, at: now)
    case .permissionDenied:
      return denied(at: now)
    default:
      failures += 1
      return retry(after: min(Self.firstBackoff * pow(2, Double(failures - 1)), Self.longestBackoff), at: now)
    }
  }

  private mutating func denied(at now: Date) -> WriteVerdict {
    switch lane {
    case .trail, .event:
      retryAt = nil
      return .dropped
    case .live:
      if forgivesPace {
        forgivesPace = false
        return retry(after: LivePolicy.spacing, at: now)
      }
      denials += 1
      return denials >= 2 ? .refused : retry(after: Self.deniedRetry, at: now)
    }
  }

  private mutating func retry(after wait: TimeInterval, at now: Date) -> WriteVerdict {
    let at = now.addingTimeInterval(wait)
    retryAt = at
    return .retry(at: at)
  }
}
