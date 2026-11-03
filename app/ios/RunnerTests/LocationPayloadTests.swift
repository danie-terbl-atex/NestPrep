import CoreLocation
import CoreMotion
import FirebaseFirestore
import XCTest

@testable import Runner

final class LocationPayloadTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_793_000_000)

  private var fixture: [String: Any] {
    get throws {
      let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("../../test/fixtures/location_payloads.json")
      return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }
  }

  private func fixtureFields(_ name: String) throws -> Set<String> {
    let entry = try XCTUnwrap(try fixture[name] as? [String: Any])
    return Set(try XCTUnwrap(entry["fields"] as? [String: Any]).keys)
  }

  private func snapshot(level: Float = 0.64, state: UIDevice.BatteryState = .unplugged) -> LiveSnapshot {
    LiveSnapshot(
      fix: Fix(latitude: -26.2041, longitude: 28.0473, accuracy: 12.4, timestamp: now),
      motion: .driving,
      battery: BatteryReading(level: level, state: state)
    )
  }

  func testTheLiveDocumentHasExactlyTheFixturesKeys() throws {
    let data = Payloads.live(snapshot(), now: now)
    XCTAssertEqual(Set(data.keys), try fixtureFields("liveContinuous"))
    XCTAssertEqual(data["point"] as? GeoPoint, GeoPoint(latitude: -26.2041, longitude: 28.0473))
    XCTAssertEqual(data["accuracyMetres"] as? Int, 12)
    XCTAssertTrue(data["reportedAt"] is FieldValue)
    XCTAssertEqual(data["sharingUntil"] as? Timestamp, Timestamp(date: now + 86_400))
    XCTAssertEqual(data["mode"] as? String, "continuous")
    XCTAssertEqual(data["batteryPercent"] as? Int, 64)
    XCTAssertEqual(data["charging"] as? Bool, false)
    XCTAssertEqual(data["motion"] as? String, "driving")
  }

  func testAnUnknownBatteryLevelIsLeftOut() {
    let data = Payloads.live(snapshot(level: -1, state: .unknown), now: now)
    XCTAssertNil(data["batteryPercent"])
    XCTAssertEqual(data["charging"] as? Bool, false)
  }

  func testAFullBatteryCountsAsCharging() {
    XCTAssertEqual(BatteryReading(level: 1, state: .full), BatteryReading(level: 1.0, state: .charging))
    XCTAssertEqual(BatteryReading(level: 1, state: .full).percent, 100)
  }

  func testTheDayFlushHasExactlyTheFixturesKeys() throws {
    let data = Payloads.trail([TrailPoint(t: 1_793_000_000, la: -26.2041, lo: 28.0473, ac: 12)], now: now)
    XCTAssertEqual(Set(data.keys), try fixtureFields("dayFlush"))
    XCTAssertTrue(data["points"] is FieldValue)
    XCTAssertTrue(data["updatedAt"] is FieldValue)
    XCTAssertEqual(data["expiresAt"] as? Timestamp, Timestamp(date: now + 30 * 86_400))
  }

  func testThePlaceEventHasExactlyTheFixturesKeys() throws {
    let data = Payloads.event(PlaceEvent(placeId: "school", kind: .arrive, crossedAt: now), now: now)
    XCTAssertEqual(Set(data.keys), try fixtureFields("placeEvent"))
    XCTAssertEqual(data["placeId"] as? String, "school")
    XCTAssertEqual(data["kind"] as? String, "arrive")
    XCTAssertTrue(data["at"] is FieldValue)
    XCTAssertEqual(data["expiresAt"] as? Timestamp, Timestamp(date: now + 30 * 86_400))
  }

  func testTheMotionLabelsAreTheFixtures() throws {
    let labels = try XCTUnwrap(try fixture["motionValues"] as? [String])
    XCTAssertEqual(labels.compactMap(MotionLabel.init(rawValue:)).map(\.rawValue), labels)
  }

  func testThePathsMatchTheFixture() throws {
    let config = try XCTUnwrap(EngineConfig(arguments: try fixture["startArguments"]))
    let paths = DocumentPaths(config)
    XCTAssertEqual(paths.live, "households/h1/memberLocations/m-sam")
    XCTAssertEqual(paths.day("2026-10-27"), "households/h1/locationTrails/m-sam/trailDays/2026-10-27")
    XCTAssertEqual(paths.event("abc"), "households/h1/locationTrails/m-sam/placeEvents/abc")
  }

  func testTheFixturesStartArgumentsParse() throws {
    let config = try XCTUnwrap(EngineConfig(arguments: try fixture["startArguments"]))
    XCTAssertEqual(
      config,
      EngineConfig(
        householdId: "h1", memberId: "m-sam", timeZone: "Africa/Johannesburg", foreground: true,
        places: [FamilyPlace(id: "school", latitude: -26.1, longitude: 28.05, radiusMetres: 150)],
        emulatorHost: nil, firestorePort: 8080, authPort: 9099))
    XCTAssertEqual(config.zone.identifier, "Africa/Johannesburg")
    XCTAssertNil(EngineConfig(arguments: ["householdId": "h1"]))
  }

  func testAnEmulatorHostIsKeptAndAnEmptyOneIsNot() throws {
    var arguments = try XCTUnwrap(try fixture["startArguments"] as? [String: Any])
    arguments["emulatorHost"] = "192.168.1.20"
    XCTAssertEqual(EngineConfig(arguments: arguments)?.emulatorHost, "192.168.1.20")
    arguments["emulatorHost"] = ""
    XCTAssertNil(EngineConfig(arguments: arguments)?.emulatorHost)
  }

  func testAConfigSavedBeforeTheEmulatorFieldsStillLoads() throws {
    let saved = Data(#"{"householdId":"h1","memberId":"m-sam","timeZone":"UTC","foreground":false,"places":[]}"#.utf8)
    let config = try JSONDecoder().decode(EngineConfig.self, from: saved)
    XCTAssertNil(config.emulatorHost)
    XCTAssertNil(config.firestorePort)
  }

  func testThePathsUseTheFixturesCollections() throws {
    let trail = try XCTUnwrap(try fixture["dayFlush"] as? [String: Any])["path"] as? String
    let event = try XCTUnwrap(try fixture["placeEvent"] as? [String: Any])["path"] as? String
    XCTAssertEqual(trail, "households/{householdId}/locationTrails/{memberId}/trailDays/{yyyy-MM-dd}")
    XCTAssertEqual(event, "households/{householdId}/locationTrails/{memberId}/placeEvents/{autoId}")
    let paths = DocumentPaths(EngineConfig(householdId: "{householdId}", memberId: "{memberId}", timeZone: "UTC", foreground: false, places: []))
    XCTAssertEqual(paths.day("{yyyy-MM-dd}"), trail)
    XCTAssertEqual(paths.event("{autoId}"), event)
    XCTAssertEqual(paths.places, "households/{householdId}/places")
  }

  func testARetryCarriesAnExpiryFromTheRetryNotTheFirstAttempt() {
    let later = now + 86_400
    let point = TrailPoint(t: 1_793_000_000, la: -26.2041, lo: 28.0473, ac: 12)
    XCTAssertEqual(Payloads.trail([point], now: later)["expiresAt"] as? Timestamp, Timestamp(date: later + 30 * 86_400))
    XCTAssertEqual(Payloads.live(snapshot(), now: later)["sharingUntil"] as? Timestamp, Timestamp(date: later + 86_400))
  }

  func testHouseholdPlacesAreReadFromTheirDocuments() {
    let places = FamilyPlace.list(fromDocuments: [
      (id: "school", data: ["centre": GeoPoint(latitude: -26.1, longitude: 28.05), "radiusMetres": 150, "name": "School"]),
      (id: "broken", data: ["name": "No centre"]),
    ])
    XCTAssertEqual(places, [FamilyPlace(id: "school", latitude: -26.1, longitude: 28.05, radiusMetres: 150)])
  }

  func testAPermissionDenialIsRecognised() {
    let denied = NSError(domain: FirestoreErrorDomain, code: FirestoreErrorCode.permissionDenied.rawValue)
    XCTAssertEqual(WriteFailure(denied), .permissionDenied)
    XCTAssertEqual(WriteFailure(NSError(domain: FirestoreErrorDomain, code: FirestoreErrorCode.unavailable.rawValue)), .other)
    XCTAssertEqual(WriteFailure(NSError(domain: NSURLErrorDomain, code: 7)), .other)
    XCTAssertEqual(
      WriteFailure(NSError(domain: FirestoreErrorDomain, code: FirestoreErrorCode.alreadyExists.rawValue)), .alreadyExists)
  }

  func testPermissionsMapToTheChannelsWords() {
    XCTAssertEqual(PermissionMap.location(.authorizedAlways, servicesEnabled: true, reducedAccuracy: false), "always")
    XCTAssertEqual(PermissionMap.location(.authorizedWhenInUse, servicesEnabled: true, reducedAccuracy: false), "whileInUse")
    XCTAssertEqual(PermissionMap.location(.notDetermined, servicesEnabled: true, reducedAccuracy: false), "denied")
    XCTAssertEqual(PermissionMap.location(.denied, servicesEnabled: true, reducedAccuracy: false), "deniedForever")
    XCTAssertEqual(PermissionMap.location(.restricted, servicesEnabled: true, reducedAccuracy: false), "deniedForever")
    XCTAssertEqual(PermissionMap.location(.authorizedAlways, servicesEnabled: false, reducedAccuracy: false), "off")
    XCTAssertEqual(PermissionMap.location(.authorizedAlways, servicesEnabled: true, reducedAccuracy: true), "whileInUse")
    XCTAssertEqual(PermissionMap.location(.authorizedWhenInUse, servicesEnabled: true, reducedAccuracy: true), "whileInUse")
    XCTAssertEqual(PermissionMap.motion(.authorized, available: true), "granted")
    XCTAssertEqual(PermissionMap.motion(.notDetermined, available: true), "denied")
    XCTAssertEqual(PermissionMap.motion(.denied, available: false), "notNeeded")
  }
}
