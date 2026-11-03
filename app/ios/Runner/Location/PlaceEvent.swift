import Foundation

struct PlaceEvent: Codable, Equatable {
  enum Kind: String, Codable {
    case arrive, leave
  }

  static let maxAge: TimeInterval = 15 * 60

  let id: String
  let placeId: String
  let kind: Kind
  let crossedAt: Date?

  init(placeId: String, kind: Kind, crossedAt: Date?, id: String = PlaceEvent.autoId()) {
    self.id = id
    self.placeId = placeId
    self.kind = kind
    self.crossedAt = crossedAt
  }

  init(_ transition: PlaceTransition, at crossedAt: Date) {
    switch transition {
    case .arrive(let placeId): self.init(placeId: placeId, kind: .arrive, crossedAt: crossedAt)
    case .leave(let placeId): self.init(placeId: placeId, kind: .leave, crossedAt: crossedAt)
    }
  }

  func isStale(at now: Date) -> Bool {
    crossedAt.map { now.timeIntervalSince($0) > Self.maxAge } ?? true
  }

  static func autoId() -> String {
    let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
    return String((0..<20).map { _ in alphabet.randomElement()! })
  }
}
