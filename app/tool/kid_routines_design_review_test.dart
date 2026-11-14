import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/kid_routines/model/kid_routine_tick.dart';
import 'package:nestprep/features/kid_routines/state/kid_routine_day_controller.dart';
import 'package:nestprep/features/kid_routines/state/kid_routines_controller.dart';
import 'package:nestprep/features/kid_routines/ui/kid_routines_screen.dart';
import 'package:nestprep/features/kid_routines/ui/kid_routines_today.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:provider/provider.dart';

import '../test/support/fake_kid_routines.dart';
import '../test/support/household_fixtures.dart';
import 'review_press.dart';

/// The parent's routines screen and the routine sheet (kid-routines
/// ADR-0001), in both themes. Pictures to look at rather than assertions:
/// regenerate with
///
///     flutter test tool/kid_routines_design_review_test.dart --update-goldens
void main() {
  setUpAll(loadEveryFont);

  for (final (name, brightness, opensSheet) in [
    ('kid-routines/screen-light', Brightness.light, false),
    ('kid-routines/screen-dark', Brightness.dark, false),
    ('kid-routines/sheet-light', Brightness.light, true),
    ('kid-routines/sheet-dark', Brightness.dark, true),
  ]) {
    testWidgets(name, (tester) async {
      final repository = FakeKidRoutineRepository();
      final controller = KidRoutinesController(
        repository: repository,
        householdId: Fixtures.householdId,
        memberId: Fixtures.samMemberId,
        canEdit: true,
        setsStars: true,
        members: [Fixtures.sam, Fixtures.kid],
      );
      addTearDown(() async {
        controller.dispose();
        await repository.close();
      });
      await captureScreen(
        tester,
        name,
        brightness: brightness,
        screen: const KidRoutinesScreen(),
        providers: [
          ChangeNotifierProvider<KidRoutinesController>.value(
            value: controller,
          ),
        ],
        emit: () async => repository.emit([KidRoutineFixtures.morning()]),
        act: () async {
          if (!opensSheet) return;
          await tester.tap(
            find.byKey(
              const ValueKey('kid-routine-${Fixtures.kidMemberId}-morning'),
            ),
          );
        },
      );
    });
  }

  for (final (name, brightness, opensPlayer) in [
    ('kid-routines/kid-card-light', Brightness.light, false),
    ('kid-routines/kid-card-dark', Brightness.dark, false),
    ('kid-routines/player-light', Brightness.light, true),
    ('kid-routines/player-dark', Brightness.dark, true),
  ]) {
    testWidgets(name, (tester) async {
      final repository = FakeKidRoutineRepository();
      final wednesday = CalendarDate(2026, 11, 4);
      final controller = KidRoutineDayController(
        repository: repository,
        householdId: Fixtures.householdId,
        kidId: Fixtures.kidMemberId,
      )..follow(show: true, canTick: true, today: wednesday);
      addTearDown(() async {
        controller.dispose();
        await repository.close();
      });
      await captureScreen(
        tester,
        name,
        brightness: brightness,
        screen: NestScaffold(
          title: 'Hi Mia',
          body: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => ListView(
              children: [
                KidRoutinesToday(controller: controller, kidName: 'Mia'),
              ],
            ),
          ),
        ),
        providers: const [],
        emit: () async => repository
          ..emit([KidRoutineFixtures.morning()])
          ..emitTicks([
            KidRoutineTick(
              routineId: 'morning',
              kidId: Fixtures.kidMemberId,
              occurrenceDate: wednesday,
              doneStepIds: const ['s1', 's2'],
              updatedBy: Fixtures.kidMemberId,
            ),
          ]),
        act: () async {
          if (!opensPlayer) return;
          await tester.tap(find.byKey(const ValueKey('kid-routine-morning')));
        },
      );
    });
  }
}
