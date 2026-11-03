import XCTest

@testable import Runner

final class LocationPlacesTests: XCTestCase {
  private let start = Date(timeIntervalSince1970: 1_793_000_000)

  func testArrivingNeedsSixtySecondsInside() {
    var presence = PlacePresence()
    XCTAssertNil(presence.observe("school", inside: true, at: start))
    XCTAssertEqual(presence.idsToCheck(at: start + 59), [])
    XCTAssertEqual(presence.nextCheck, start + 60)
    XCTAssertNil(presence.observe("school", inside: true, at: start + 59))
    XCTAssertEqual(presence.idsToCheck(at: start + 60), ["school"])
    XCTAssertEqual(presence.observe("school", inside: true, at: start + 60), .arrive("school"))
    XCTAssertNil(presence.nextCheck)
  }

  func testLeavingBeforeTheDwellIsNotAVisit() {
    var presence = PlacePresence()
    _ = presence.observe("school", inside: true, at: start)
    XCTAssertNil(presence.observe("school", inside: false, at: start + 30))
    XCTAssertNil(presence.observe("school", inside: true, at: start + 61))
  }

  func testAnExitSoonAfterArrivingWaitsForTheGrace() {
    var presence = arrived(at: start)
    XCTAssertNil(presence.observe("school", inside: false, at: start + 60))
    XCTAssertEqual(presence.nextCheck, start + 180)
    XCTAssertEqual(presence.idsToCheck(at: start + 179), [])
    XCTAssertEqual(presence.idsToCheck(at: start + 180), ["school"])
    XCTAssertEqual(presence.observe("school", inside: false, at: start + 180), .leave("school"))
  }

  func testComingBackInsideTheGraceCancelsTheLeave() {
    var presence = arrived(at: start)
    _ = presence.observe("school", inside: false, at: start + 60)
    XCTAssertNil(presence.observe("school", inside: true, at: start + 90))
    XCTAssertNil(presence.nextCheck)
    XCTAssertEqual(presence.observe("school", inside: false, at: start + 600), .leave("school"))
  }

  func testAnExitAfterTheGraceLeavesAtOnce() {
    var presence = arrived(at: start)
    XCTAssertEqual(presence.observe("school", inside: false, at: start + 180), .leave("school"))
    XCTAssertNil(presence.observe("school", inside: false, at: start + 200))
  }

  func testAnExitWithoutAnArrivalSaysNothing() {
    var presence = PlacePresence()
    XCTAssertNil(presence.observe("school", inside: false, at: start))
  }

  func testRemovedPlacesAreForgotten() {
    var presence = arrived(at: start)
    presence.keep(only: [])
    XCTAssertNil(presence.observe("school", inside: false, at: start + 600))
  }

  func testTheNineteenNearestPlacesAreMonitored() {
    let here = Fix(latitude: 0, longitude: 0, accuracy: 10, timestamp: start)
    let places = (1...25).reversed().map {
      FamilyPlace(id: "p\($0)", latitude: Double($0) / 100, longitude: 0, radiusMetres: 100)
    }
    let picked = RegionPlanner.places(places, nearest: here)
    XCTAssertEqual(picked.map(\.id), (1...19).map { "p\($0)" })
    XCTAssertEqual(RegionPlanner.places(places, nearest: nil).count, 19)
  }

  func testAPlaceIsReplannedAfterHalfAKilometre() {
    let anchor = Fix(latitude: 0, longitude: 0, accuracy: 10, timestamp: start)
    let near = Fix(latitude: 0.004, longitude: 0, accuracy: 10, timestamp: start)
    let far = Fix(latitude: 0.005, longitude: 0, accuracy: 10, timestamp: start)
    XCTAssertTrue(RegionPlanner.needsReplan(plannedAround: nil, now: near))
    XCTAssertFalse(RegionPlanner.needsReplan(plannedAround: anchor, now: near))
    XCTAssertTrue(RegionPlanner.needsReplan(plannedAround: anchor, now: far))
  }

  func testAFixInsideTheRadiusIsInside() {
    let school = FamilyPlace(id: "school", latitude: -26.1, longitude: 28.05, radiusMetres: 150)
    XCTAssertTrue(Fix(latitude: -26.1009, longitude: 28.05, accuracy: 5, timestamp: start).isInside(school))
    XCTAssertFalse(Fix(latitude: -26.102, longitude: 28.05, accuracy: 5, timestamp: start).isInside(school))
  }

  func testAPlaceEventIdLooksLikeAFirestoreAutoId() {
    let id = PlaceEvent.autoId()
    XCTAssertEqual(id.count, 20)
    XCTAssertTrue(id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber) })
    XCTAssertEqual(PlaceEvent(.leave("home"), at: start).kind, .leave)
  }

  func testACrossingOlderThanFifteenMinutesIsStale() {
    let event = PlaceEvent(.arrive("school"), at: start)
    XCTAssertFalse(event.isStale(at: start + 900))
    XCTAssertTrue(event.isStale(at: start + 901))
    XCTAssertTrue(PlaceEvent(placeId: "school", kind: .arrive, crossedAt: nil).isStale(at: start))
  }

  func testAVisitInsideAPlaceArrivesWithoutWaitingForTheDwell() {
    var presence = PlacePresence()
    _ = presence.observe("school", inside: true, at: start)
    XCTAssertEqual(presence.visit("school", at: start + 5), .arrive("school"))
    XCTAssertNil(presence.visit("school", at: start + 10))
    XCTAssertEqual(presence.awaitingDwell, [])
  }

  func testAVisitCancelsAPendingLeave() {
    var presence = arrived(at: start)
    _ = presence.observe("school", inside: false, at: start + 60)
    XCTAssertNil(presence.visit("school", at: start + 90))
    XCTAssertNil(presence.nextCheck)
  }

  func testTheAddressIsOneLine() {
    XCTAssertEqual(
      AddressLookup.line(number: "12", street: "Oak Street", area: "Parkhurst", name: "12 Oak Street"),
      "12 Oak Street, Parkhurst")
    XCTAssertEqual(AddressLookup.line(number: nil, street: nil, area: "Parkhurst", name: "Parkhurst"), "Parkhurst")
    XCTAssertEqual(AddressLookup.line(number: nil, street: "Oak Street", area: nil, name: nil), "Oak Street")
    XCTAssertNil(AddressLookup.line(number: " ", street: nil, area: nil, name: nil))
  }

  private func arrived(at date: Date) -> PlacePresence {
    var presence = PlacePresence()
    _ = presence.observe("school", inside: true, at: date - 60)
    _ = presence.observe("school", inside: true, at: date)
    return presence
  }
}
