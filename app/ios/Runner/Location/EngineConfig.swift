import Foundation

struct FamilyPlace: Codable, Equatable {
  let id: String
  let latitude: Double
  let longitude: Double
  let radiusMetres: Double

  init(id: String, latitude: Double, longitude: Double, radiusMetres: Double) {
    self.id = id
    self.latitude = latitude
    self.longitude = longitude
    self.radiusMetres = radiusMetres
  }

  init?(argument: Any) {
    guard let map = argument as? [String: Any],
      let id = map["id"] as? String,
      let latitude = (map["latitude"] as? NSNumber)?.doubleValue,
      let longitude = (map["longitude"] as? NSNumber)?.doubleValue,
      let radius = (map["radiusMetres"] as? NSNumber)?.doubleValue
    else { return nil }
    self.init(id: id, latitude: latitude, longitude: longitude, radiusMetres: radius)
  }

  static func list(from argument: Any?) -> [FamilyPlace] {
    (argument as? [Any] ?? []).compactMap(FamilyPlace.init(argument:))
  }
}

struct EngineConfig: Codable, Equatable {
  let householdId: String
  let memberId: String
  let timeZone: String
  var foreground: Bool
  var places: [FamilyPlace]
  let emulatorHost: String?
  let firestorePort: Int?
  let authPort: Int?

  init(
    householdId: String, memberId: String, timeZone: String, foreground: Bool, places: [FamilyPlace],
    emulatorHost: String? = nil, firestorePort: Int? = nil, authPort: Int? = nil
  ) {
    self.householdId = householdId
    self.memberId = memberId
    self.timeZone = timeZone
    self.foreground = foreground
    self.places = places
    self.emulatorHost = emulatorHost
    self.firestorePort = firestorePort
    self.authPort = authPort
  }

  init?(arguments: Any?) {
    guard let map = arguments as? [String: Any],
      let householdId = map["householdId"] as? String,
      let memberId = map["memberId"] as? String,
      let timeZone = map["timeZone"] as? String
    else { return nil }
    self.init(
      householdId: householdId,
      memberId: memberId,
      timeZone: timeZone,
      foreground: map["foreground"] as? Bool ?? false,
      places: FamilyPlace.list(from: map["places"]),
      emulatorHost: (map["emulatorHost"] as? String).flatMap { $0.isEmpty ? nil : $0 },
      firestorePort: (map["firestorePort"] as? NSNumber)?.intValue,
      authPort: (map["authPort"] as? NSNumber)?.intValue
    )
  }

  var zone: TimeZone { TimeZone(identifier: timeZone) ?? .current }

  func isSameSession(as other: EngineConfig) -> Bool {
    householdId == other.householdId && memberId == other.memberId
  }

  func place(_ id: String) -> FamilyPlace? { places.first { $0.id == id } }
}
