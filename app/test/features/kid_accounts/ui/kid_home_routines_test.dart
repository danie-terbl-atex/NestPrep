import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/chore_points/state/kid_points_controller.dart';
import 'package:nestprep/features/kid_accounts/state/kid_home_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_home_screen.dart';
import 'package:nestprep/features/kid_routines/state/kid_routine_day_controller.dart';
import 'package:nestprep/features/kid_routines/ui/kid_routine_player.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_kid_routines.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/kid_home_fixture.dart';
import '../../../support/pump_screen.dart';

/// Today's routines on the kid's home (kid-routines ADR-0001), wired the way
/// the route wires them: they follow what the home knows.
void main() {
  setUpAll(tz_data.initializeTimeZones);

  late KidHomeFixture fixture;
  late FakeKidRoutineRepository repository;
  late KidRoutineDayController routines;

  void follow() => routines.follow(
    show: fixture.controller.areas?.chores ?? false,
    canTick: fixture.controller.areas?.canTick ?? false,
    today: fixture.controller.today,
  );

  setUp(() {
    fixture = KidHomeFixture();
    repository = FakeKidRoutineRepository();
    routines = KidRoutineDayController(
      repository: repository,
      householdId: Fixtures.householdId,
      kidId: Fixtures.kidMemberId,
    );
    fixture.controller.addListener(follow);
  });

  tearDown(() async {
    fixture.controller.removeListener(follow);
    routines.dispose();
    await repository.close();
    await fixture.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpScreen(
      tester,
      const KidHomeScreen(),
      providers: [
        ChangeNotifierProvider<KidHomeController>.value(
          value: fixture.controller,
        ),
        ChangeNotifierProvider<KidPointsController>.value(value: fixture.stars),
        ChangeNotifierProvider<KidRoutineDayController>.value(value: routines),
      ],
    );
    await tester.runAsync(
      () =>
          fixture.arrive(tasks: [KidHomeFixture.chore('bed', 'Make your bed')]),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a day with no routine shows the jobs as before', (tester) async {
    await pump(tester);
    repository
      ..emit([])
      ..emitTicks([]);
    await tester.pumpAndSettle();
    expect(find.text(KidRoutineCopy.kidTitle), findsNothing);
    expect(find.text(KidCopy.choresTitle), findsOneWidget);
  });

  testWidgets('today’s routine sits above the jobs and opens the player', (
    tester,
  ) async {
    await pump(tester);
    repository
      ..emit([
        KidRoutineFixtures.morning().copyWith(
          firstDate: CalendarDate(2026, 9, 1),
        ),
      ])
      ..emitTicks([]);
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('kid-routine-morning'));
    expect(card, findsOneWidget);
    // The jobs are further down the page than the routine.
    expect(find.text(KidCopy.choresTitle), findsNothing);
    await tester.scrollUntilVisible(find.text(KidCopy.choresTitle), 200);
    await tester.scrollUntilVisible(card, -200);
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byKey(KidRoutinePlayer.doneKey), findsOneWidget);
    expect(find.text('Get dressed'), findsOneWidget);
  });
}
