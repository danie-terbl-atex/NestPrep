import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/model/coordinates.dart';
import 'package:nestprep/features/live_location/model/trail.dart';
import 'package:nestprep/features/live_location/state/history_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_live_location.dart';

void main() {
  tz_data.initializeTimeZones();
  final now = DateTime.utc(2026, 11, 2, 10);
  final clock = HouseholdClock('Africa/Johannesburg', now: () => now);
  late FakeTrailRepository trails;
  late FakePlacesRepository places;

  setUp(() {
    trails = FakeTrailRepository();
    places = FakePlacesRepository();
  });

  tearDown(() => places.close());

  HistoryController controller() => HistoryController(
    trailRepository: trails,
    placesRepository: places,
    householdId: 'h1',
    memberId: 'm-mia',
    clock: clock,
  );

  test('opens on today, read once', () async {
    trails.days['2026-11-02'] = TrailDay(
      points: [
        TrailPoint(
          at: now,
          point: const Coordinates(latitude: -26.1, longitude: 28.05),
          accuracyMetres: 10,
        ),
      ],
      events: const [],
    );
    final history = controller();
    await Future<void>.delayed(Duration.zero);

    expect(trails.asked, [CalendarDate(2026, 11, 2)]);
    expect(history.view, isA<AsyncData<MemberDay>>());
    expect(history.canGoForward, isFalse);
    history.dispose();
  });

  test('walks back thirty days and no further', () async {
    final history = controller();
    for (var day = 0; day < 40; day++) {
      await history.previousDay();
    }
    expect(history.day, CalendarDate(2026, 10, 4));
    expect(history.canGoBack, isFalse);
    await history.nextDay();
    expect(history.day, CalendarDate(2026, 10, 5));
    history.dispose();
  });

  test('a refused read is a failure the screen can retry', () async {
    trails.failWith = const PermissionDeniedFailure();
    final history = controller();
    await Future<void>.delayed(Duration.zero);
    expect(history.view, isA<AsyncFailure<MemberDay>>());

    trails.failWith = null;
    await history.retry();
    expect(history.view, isA<AsyncData<MemberDay>>());
    history.dispose();
  });

  test('clearing my history clears it and reads the day again', () async {
    final history = controller();
    await history.clearHistory();
    expect(trails.cleared, 1);
    expect(trails.asked, hasLength(2));
    history.dispose();
  });
}
