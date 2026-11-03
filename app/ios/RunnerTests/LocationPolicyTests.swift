import XCTest

@testable import Runner

final class LocationPolicyTests: XCTestCase {
  private let start = Date(timeIntervalSince1970: 1_793_000_000)

  private func fix(_ north: Double = 0, accuracy: Double = 10, at seconds: TimeInterval = 0) -> Fix {
    Fix(latitude: -26.2041 + north / 111_320, longitude: 28.0473, accuracy: accuracy, timestamp: start + seconds)
  }

  private func written(_ fix: Fix, motion: MotionLabel = .driving) -> LiveWrite {
    LiveWrite(fix: fix, motion: motion, completedAt: start)
  }

  func testTheFirstLiveWriteAlwaysGoes() {
    XCTAssertTrue(LivePolicy.shouldWrite(fix(), motion: .unknown, foreground: false, since: nil, now: start))
  }

  func testForegroundWaitsTwentySecondsAndNeedsMovementOrNewMotion() {
    let last = written(fix())
    XCTAssertFalse(LivePolicy.shouldWrite(fix(30), motion: .driving, foreground: true, since: last, now: start + 19))
    XCTAssertTrue(LivePolicy.shouldWrite(fix(30), motion: .driving, foreground: true, since: last, now: start + 20))
    XCTAssertFalse(LivePolicy.shouldWrite(fix(10), motion: .driving, foreground: true, since: last, now: start + 60))
    XCTAssertTrue(LivePolicy.shouldWrite(fix(10), motion: .onFoot, foreground: true, since: last, now: start + 60))
  }

  func testBackgroundWritesEveryTwoMinutesOrAfterAFastLongMove() {
    let last = written(fix())
    XCTAssertFalse(LivePolicy.shouldWrite(fix(200), motion: .driving, foreground: false, since: last, now: start + 60))
    XCTAssertTrue(LivePolicy.shouldWrite(fix(10), motion: .driving, foreground: false, since: last, now: start + 120))
    XCTAssertFalse(LivePolicy.shouldWrite(fix(300), motion: .driving, foreground: false, since: last, now: start + 14))
    XCTAssertTrue(LivePolicy.shouldWrite(fix(300), motion: .driving, foreground: false, since: last, now: start + 15))
  }

  func testTheLeaseIsRenewedAfterAnHour() {
    let last = written(fix())
    XCTAssertFalse(LivePolicy.needsRenewal(since: last, now: start + 3_599))
    XCTAssertTrue(LivePolicy.needsRenewal(since: last, now: start + 3_600))
    XCTAssertTrue(LivePolicy.needsRenewal(since: nil, now: start))
  }

  func testStillAfterFiveMinutesWithinFiftyMetres() {
    var detector = StillnessDetector()
    detector.reset(anchor: fix(), at: start)
    detector.observe(fix(40), at: start + 200)
    XCTAssertFalse(detector.isStill(at: start + 299))
    XCTAssertTrue(detector.isStill(at: start + 300))
  }

  func testMovingFiftyMetresRestartsTheStillnessWindow() {
    var detector = StillnessDetector()
    detector.reset(anchor: fix(), at: start)
    detector.observe(fix(60), at: start + 200)
    XCTAssertFalse(detector.isStill(at: start + 300))
    XCTAssertEqual(detector.deadline, start + 500)
  }

  func testStillnessNeedsAFix() {
    var detector = StillnessDetector()
    detector.reset(anchor: nil, at: start)
    XCTAssertFalse(detector.isStill(at: start + 600))
  }

  func testTrailRecordsAccurateFixesThirtyMetresOrFiveMinutesApart() {
    XCTAssertTrue(TrailPolicy.shouldRecord(fix(), after: nil))
    XCTAssertFalse(TrailPolicy.shouldRecord(fix(accuracy: 101), after: nil))
    XCTAssertFalse(TrailPolicy.shouldRecord(fix(accuracy: -1), after: nil))
    XCTAssertFalse(TrailPolicy.shouldRecord(fix(20, at: 60), after: fix()))
    XCTAssertTrue(TrailPolicy.shouldRecord(fix(31, at: 60), after: fix()))
    XCTAssertTrue(TrailPolicy.shouldRecord(fix(5, at: 300), after: fix()))
  }

  func testTrailPointsAreAtLeastFifteenSecondsApartHoweverFastTheCar() {
    XCTAssertFalse(TrailPolicy.shouldRecord(fix(400, at: 14), after: fix()))
    XCTAssertTrue(TrailPolicy.shouldRecord(fix(400, at: 15), after: fix()))
  }

  func testTrailFlushesAtThirtyPointsOrFifteenMinutes() {
    XCTAssertFalse(TrailPolicy.shouldFlush(buffered: 29, lastFlush: start, now: start + 899))
    XCTAssertTrue(TrailPolicy.shouldFlush(buffered: 30, lastFlush: start, now: start + 1))
    XCTAssertTrue(TrailPolicy.shouldFlush(buffered: 1, lastFlush: start, now: start + 900))
  }

  func testWriteGateSendsOneAtATimeSpacedFromCompletion() {
    var gate = WriteGate(lane: .live, spacing: 12)
    XCTAssertTrue(gate.canSend(at: start))
    gate.begin(at: start)
    XCTAssertNil(gate.earliestSend)
    XCTAssertFalse(gate.canSend(at: start + 100))
    gate.succeed(at: start + 5)
    XCTAssertFalse(gate.canSend(at: start + 16))
    XCTAssertTrue(gate.canSend(at: start + 17))
  }

  func testASecondConsecutiveLiveDenialRefuses() {
    var gate = WriteGate(lane: .live, spacing: 12)
    gate.begin(at: start)
    XCTAssertEqual(gate.fail(.permissionDenied, at: start), .retry(at: start + 30))
    XCTAssertFalse(gate.canSend(at: start + 29))
    XCTAssertTrue(gate.canSend(at: start + 30))
    gate.begin(at: start + 30)
    XCTAssertEqual(gate.fail(.permissionDenied, at: start + 30), .refused)
  }

  func testASuccessForgivesAnEarlierDenial() {
    var gate = WriteGate(lane: .live, spacing: 0)
    gate.begin(at: start)
    _ = gate.fail(.permissionDenied, at: start)
    gate.begin(at: start + 30)
    gate.succeed(at: start + 30)
    gate.begin(at: start + 60)
    XCTAssertEqual(gate.fail(.permissionDenied, at: start + 60), .retry(at: start + 90))
  }

  func testADeniedTrailOrEventWriteIsDroppedAndNeverRefuses() {
    for lane in [WriteLane.trail, .event] {
      var gate = WriteGate(lane: lane, spacing: 0)
      for attempt in 0..<3 {
        gate.begin(at: start + Double(attempt))
        XCTAssertEqual(gate.fail(.permissionDenied, at: start + Double(attempt)), .dropped)
      }
      XCTAssertTrue(gate.canSend(at: start + 3))
    }
  }

  func testAnEventThatAlreadyExistsHasLanded() {
    var gate = WriteGate(lane: .event, spacing: 0)
    gate.begin(at: start)
    XCTAssertEqual(gate.fail(.alreadyExists, at: start + 1), .settled)
    XCTAssertEqual(gate.lastCompletion, start + 1)
    var live = WriteGate(lane: .live, spacing: 0)
    live.begin(at: start)
    XCTAssertEqual(live.fail(.alreadyExists, at: start), .retry(at: start + 30))
  }

  func testADenialOfAWriteQueuedOverFiveMinutesIsRetriedAtOnceAndNotCounted() {
    var gate = WriteGate(lane: .live, spacing: 12)
    gate.begin(at: start)
    XCTAssertEqual(gate.fail(.permissionDenied, at: start + 86_400), .retry(at: start + 86_400))
    gate.begin(at: start + 86_400)
    XCTAssertEqual(gate.fail(.permissionDenied, at: start + 86_401), .retry(at: start + 86_431))
    gate.begin(at: start + 86_431)
    XCTAssertEqual(gate.fail(.permissionDenied, at: start + 86_432), .refused)

    var trail = WriteGate(lane: .trail, spacing: 0)
    trail.begin(at: start)
    XCTAssertEqual(trail.fail(.permissionDenied, at: start + 301), .retry(at: start + 301))
  }

  func testAFreshEnginesFirstPaceDenialIsRetriedAfterTwelveSecondsUncounted() {
    var gate = WriteGate(lane: .live, spacing: 12, fresh: true)
    gate.begin(at: start)
    XCTAssertEqual(gate.fail(.permissionDenied, at: start), .retry(at: start + 12))
    gate.begin(at: start + 12)
    XCTAssertEqual(gate.fail(.permissionDenied, at: start + 12), .retry(at: start + 42))
    gate.begin(at: start + 42)
    XCTAssertEqual(gate.fail(.permissionDenied, at: start + 42), .refused)
  }

  func testOtherFailuresBackOffUpToFifteenMinutes() {
    var gate = WriteGate(lane: .live, spacing: 0)
    let waits = (0..<8).map { _ -> TimeInterval in
      gate.begin(at: start)
      guard case .retry(let at) = gate.fail(.other, at: start) else { return -1 }
      return at.timeIntervalSince(start)
    }
    XCTAssertEqual(waits, [30, 60, 120, 240, 480, 900, 900, 900])
  }

  func testOnlyFreshAccurateFixesDriveTheEngine() {
    XCTAssertTrue(FixFilter.isUsable(fix(accuracy: 100, at: 0), at: start + 60, reducedAccuracy: false))
    XCTAssertFalse(FixFilter.isUsable(fix(accuracy: 101, at: 0), at: start, reducedAccuracy: false))
    XCTAssertFalse(FixFilter.isUsable(fix(accuracy: 10, at: 0), at: start + 61, reducedAccuracy: false))
    XCTAssertFalse(FixFilter.isUsable(fix(accuracy: -1, at: 0), at: start, reducedAccuracy: false))
    XCTAssertTrue(FixFilter.isUsable(fix(accuracy: 3_000, at: 0), at: start, reducedAccuracy: true))
    XCTAssertFalse(FixFilter.isUsable(fix(accuracy: 3_000, at: 0), at: start + 61, reducedAccuracy: true))
  }

  func testTheStillAlarmIsNeverArmedWithoutAnAnchorOrInThePast() {
    var detector = StillnessDetector()
    detector.reset(anchor: nil, at: start)
    XCTAssertNil(detector.alarm(at: start))
    detector.reset(anchor: fix(), at: start)
    XCTAssertEqual(detector.alarm(at: start + 10), start + 300)
    XCTAssertNil(detector.alarm(at: start + 300))
    XCTAssertNil(detector.alarm(at: start + 900))
  }
}
