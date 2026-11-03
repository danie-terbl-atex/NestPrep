import Foundation

enum StopReason: String {
  case refused, permissionRevoked, signedOut
}

final class EngineStore {
  private let defaults: UserDefaults

  init(defaults: UserDefaults = UserDefaults(suiteName: "io.nullstate.nestprep.location") ?? .standard) {
    self.defaults = defaults
  }

  var config: EngineConfig? {
    get { read("config") }
    set { write(newValue, "config") }
  }

  var lastStopReason: StopReason? {
    get { defaults.string(forKey: "lastStopReason").flatMap(StopReason.init(rawValue:)) }
    set { defaults.set(newValue?.rawValue, forKey: "lastStopReason") }
  }

  var askedAlways: Bool {
    get { defaults.bool(forKey: "askedAlways") }
    set { defaults.set(newValue, forKey: "askedAlways") }
  }

  var uid: String? {
    get { defaults.string(forKey: "uid") }
    set { defaults.set(newValue, forKey: "uid") }
  }

  var lastFix: Fix? {
    get { read("lastFix") }
    set { write(newValue, "lastFix") }
  }

  var lastLive: LiveWrite? {
    get { read("lastLive") }
    set { write(newValue, "lastLive") }
  }

  var stillCentre: Fix? {
    get { read("stillCentre") }
    set { write(newValue, "stillCentre") }
  }

  var presence: PlacePresence {
    get { read("presence") ?? PlacePresence() }
    set { write(newValue, "presence") }
  }

  var events: [PlaceEvent] {
    get { read("events") ?? [] }
    set { write(newValue, "events") }
  }

  var ledger: TrailLedger {
    get { read("ledger") ?? TrailLedger() }
    set { write(newValue, "ledger") }
  }

  func clearSession() {
    for key in ["config", "uid", "lastFix", "lastLive", "stillCentre", "presence", "events", "ledger"] {
      defaults.removeObject(forKey: key)
    }
  }

  private func read<Value: Decodable>(_ key: String) -> Value? {
    defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(Value.self, from: $0) }
  }

  private func write<Value: Encodable>(_ value: Value?, _ key: String) {
    guard let value, let data = try? JSONEncoder().encode(value) else {
      defaults.removeObject(forKey: key)
      return
    }
    defaults.set(data, forKey: key)
  }
}
