import XCTest

@testable import Runner

final class LocationTrailTests: XCTestCase {
  private let johannesburg = TimeZone(identifier: "Africa/Johannesburg")!
  private let start = Date(timeIntervalSince1970: 1_793_000_000)

  private func point(_ t: Int64) -> TrailPoint { TrailPoint(t: t, la: -26.2041, lo: 28.0473, ac: 12) }

  func testAPointFromAFixRoundsAccuracyAndTruncatesTime() {
    let fix = Fix(latitude: -26.2041, longitude: 28.0473, accuracy: 12.4, timestamp: Date(timeIntervalSince1970: 1_793_000_000.9))
    XCTAssertEqual(TrailPoint(fix), TrailPoint(t: 1_793_000_000, la: -26.2041, lo: 28.0473, ac: 12))
  }

  func testTheDayIsTheHouseholdsDate() {
    let lateUtc = point(1_793_052_000)
    XCTAssertEqual(lateUtc.day(in: TimeZone(identifier: "UTC")!), "2026-10-26")
    XCTAssertEqual(lateUtc.day(in: johannesburg), "2026-10-27")
  }

  func testAPointMapHasExactlyTheFourShortKeys() {
    let fields = point(1).fields
    XCTAssertEqual(Set(fields.keys), ["t", "la", "lo", "ac"])
    XCTAssertTrue(fields["t"] is Int64)
    XCTAssertTrue(fields["ac"] is Int)
  }

  func testAFlushTakesAtMostOneHundredAndTwentyPointsOfOneDay() {
    let points = (0..<200).map { point(1_793_000_000 + Int64($0)) }
    let plan = TrailPlanner.plan(points, zone: johannesburg, ledger: TrailLedger(), now: start)
    XCTAssertEqual(plan.batch?.points.count, 120)
    XCTAssertEqual(plan.batch?.points.first, points.first)
    XCTAssertEqual(plan.dropped, [])
  }

  func testEachDayGetsItsOwnWrite() {
    let yesterday = point(1_793_000_000)
    let today = point(1_793_000_000 + 86_400)
    let plan = TrailPlanner.plan([yesterday, today], zone: johannesburg, ledger: TrailLedger(), now: start)
    XCTAssertEqual(plan.batch, TrailBatch(day: yesterday.day(in: johannesburg), points: [yesterday]))
  }

  func testADayDocWrittenUnderThirtySecondsAgoWaits() {
    let yesterday = point(1_793_000_000)
    let today = point(1_793_000_000 + 86_400)
    var ledger = TrailLedger()
    ledger.record(TrailBatch(day: yesterday.day(in: johannesburg), points: [yesterday]), at: start)

    let plan = TrailPlanner.plan([yesterday, today], zone: johannesburg, ledger: ledger, now: start + 10)
    XCTAssertEqual(plan.batch?.day, today.day(in: johannesburg))
    XCTAssertEqual(plan.retryAt, start + 30)

    let waiting = TrailPlanner.plan([yesterday], zone: johannesburg, ledger: ledger, now: start + 10)
    XCTAssertNil(waiting.batch)
    XCTAssertEqual(waiting.retryAt, start + 30)
  }

  func testPointsBeyondThreeThousandADayAreDropped() {
    let day = point(1_793_000_000).day(in: johannesburg)
    var ledger = TrailLedger()
    ledger.sent[day] = 2_998
    let points = (0..<5).map { point(1_793_000_000 + Int64($0)) }
    let plan = TrailPlanner.plan(points, zone: johannesburg, ledger: ledger, now: start)
    XCTAssertEqual(plan.batch?.points, Array(points.prefix(2)))
    XCTAssertEqual(plan.dropped, Array(points.suffix(3)))
  }

  func testTheLedgerKeepsOnlyRecentDays() {
    var ledger = TrailLedger()
    for day in ["2026-10-01", "2026-10-02", "2026-10-03", "2026-10-04"] {
      ledger.record(TrailBatch(day: day, points: [point(1)]), at: start)
    }
    XCTAssertEqual(Set(ledger.sent.keys), ["2026-10-02", "2026-10-03", "2026-10-04"])
    XCTAssertEqual(Set(ledger.lastWrite.keys), ["2026-10-02", "2026-10-03", "2026-10-04"])
  }

  func testTheBufferKeepsTheNewestThreeThousand() {
    let points = (0..<3_005).map { point(Int64($0)) }
    let capped = TrailBuffer.capped(points)
    XCTAssertEqual(capped.count, 3_000)
    XCTAssertEqual(capped.first, point(5))
  }

  func testTheBufferSurvivesARelaunchAndForgetsWhatWasSent() throws {
    let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jsonl")
    defer { try? FileManager.default.removeItem(at: file) }
    let buffer = TrailBuffer(file: file)
    buffer.append(point(1))
    buffer.append(point(2))
    buffer.append(point(3))
    XCTAssertEqual(TrailBuffer(file: file).points, [point(1), point(2), point(3)])

    buffer.remove([point(1), point(3)])
    XCTAssertEqual(TrailBuffer(file: file).points, [point(2)])

    buffer.clear()
    XCTAssertEqual(TrailBuffer(file: file).points, [])
  }
}
