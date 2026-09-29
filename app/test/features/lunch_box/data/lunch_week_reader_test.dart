import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/data/lunch_week_reader.dart';
import 'package:nestprep/features/lunch_box/model/lunch_pick.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_week_items.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_lunch_repository.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/lunch_fixtures.dart';

/// The read API groceries phase 2 consumes (lunch-box overview, *Contracts*):
/// one household week, summed per item, live.
void main() {
  late FakeLunchRepository repository;
  setUp(() => repository = FakeLunchRepository());
  tearDown(() => repository.close());

  test(
    'emits the week’s items once plans and library have both answered',
    () async {
      final emitted = <List<LunchWeekItem>>[];
      final subscription = LunchWeekReader(repository)
          .watchWeekItems(Fixtures.householdId, LunchFixtures.week)
          .listen(emitted.add);
      addTearDown(subscription.cancel);

      repository.emitPlans([
        LunchFixtures.plan(
          LunchFixtures.lwaziId,
          slots: {
            LunchFixtures.key(1, LunchSlot.fruit): LunchPick.of(
              LunchFixtures.apple,
            ),
          },
        ),
      ]);
      await pumpEventQueue();
      expect(emitted, isEmpty);

      repository.emitItems(LunchFixtures.library);
      await pumpEventQueue();
      expect(emitted.single.single.itemId, 'apple');
      expect(emitted.single.single.portions, 1);
      // It asked for that one week, no history.
      expect(repository.watchedWindows.single, (
        from: '2026-W40',
        to: '2026-W40',
      ));
    },
  );

  test('passes a refusal on to its reader', () async {
    final errors = <Object>[];
    final subscription = LunchWeekReader(repository)
        .watchWeekItems(Fixtures.householdId, LunchFixtures.week)
        .listen((_) {}, onError: errors.add);
    addTearDown(subscription.cancel);
    repository.failItemsWith(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(errors.single, isA<PermissionDeniedFailure>());
  });
}
