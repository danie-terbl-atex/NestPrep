import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/secure_storage_packing_choice_store.dart';
import 'package:nestprep/features/plan_week/model/treat_days.dart';
import 'package:nestprep/features/plan_week/model/treat_days_shortcut.dart';
import 'package:nestprep/features/plan_week/state/plan_week_packing.dart';

import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/plan_week_packing.dart';

/// The brief's treat days (lunch-box ADR-0025): Friday until the parent
/// says, any school days or none, remembered on the phone with the rest of
/// the packing choice — and a choice kept before treat days existed still
/// reads as Friday.
void main() {
  late FakePackingChoiceStore store;

  PlanWeekPacking packing() => PlanWeekPacking(
    store: store,
    householdId: Fixtures.householdId,
    onChange: () {},
  );

  setUp(() => store = FakePackingChoiceStore());

  group('chosen in the brief', () {
    test('start as Friday only, as Plan my week always planned', () {
      final choices = packing();
      expect(choices.treatDays, TreatDays.fridayOnly);
      expect(choices.choice.treatDays, TreatDays.fridayOnly);
      expect(
        TreatDaysShortcut.fridaysOnly.isChosenFor(choices.treatDays),
        isTrue,
      );
    });

    test('a shortcut sets exactly its days, and fine-tuning one day turns '
        'the shortcut off', () async {
      final choices = packing()
        ..chooseTreatDays(TreatDaysShortcut.everyDay.days);
      expect(choices.treatDays, {1, 2, 3, 4, 5});
      choices.toggleTreatDay(DateTime.wednesday);
      expect(choices.treatDays, {1, 2, 4, 5});
      for (final shortcut in TreatDaysShortcut.values) {
        expect(shortcut.isChosenFor(choices.treatDays), isFalse);
      }
      await pumpEventQueue();
      expect(store.kept[Fixtures.householdId]!.treatDays, {1, 2, 4, 5});
    });

    test('may be no day at all, which leaves the treat out of the plan but '
        'not out of the box choice', () {
      final choices = packing()..chooseTreatDays(TreatDaysShortcut.none.days);
      expect(choices.treatDays, isEmpty);
      expect(choices.slots, contains(LunchSlot.treat));
      expect(choices.plannedSlots, isNot(contains(LunchSlot.treat)));
      choices.toggleTreatDay(DateTime.monday);
      expect(choices.plannedSlots, contains(LunchSlot.treat));
    });

    test('never take a weekend day', () {
      final choices = packing()
        ..toggleTreatDay(DateTime.saturday)
        ..chooseTreatDays({DateTime.sunday, DateTime.tuesday});
      expect(choices.treatDays, {DateTime.tuesday});
    });

    test('come back on the next visit', () async {
      store.kept[Fixtures.householdId] = packingFor(
        {...LunchSlot.values},
        treatDays: {DateTime.monday, DateTime.thursday},
      );
      final next = packing();
      await next.restore();
      expect(next.treatDays, {DateTime.monday, DateTime.thursday});
    });
  });

  group('kept on the phone', () {
    test('as Monday-first school days', () {
      final stored = SecureStoragePackingChoiceStore.toStored(
        packingFor({LunchSlot.treat}, treatDays: {5, 1, 3}),
      );
      expect(stored, contains('"treatDays":[1,3,5]'));
      expect(SecureStoragePackingChoiceStore.fromStored(stored)!.treatDays, {
        1,
        3,
        5,
      });
    });

    test('a choice kept before treat days existed reads as Friday', () {
      final legacy = SecureStoragePackingChoiceStore.fromStored(
        '{"preferences":["airFryer"],"slots":["main","treat"]}',
      )!;
      expect(legacy.treatDays, TreatDays.fridayOnly);
      expect(legacy.slots, {LunchSlot.main, LunchSlot.treat});
    });

    test('a kept "no treats" stays none, and days this build cannot read '
        'are dropped', () {
      expect(
        SecureStoragePackingChoiceStore.fromStored(
          '{"preferences":[],"slots":["treat"],"treatDays":[]}',
        )!.treatDays,
        isEmpty,
      );
      expect(
        SecureStoragePackingChoiceStore.fromStored(
          '{"preferences":[],"slots":["treat"],"treatDays":[0,2,"5",6,2]}',
        )!.treatDays,
        {DateTime.tuesday},
      );
      expect(
        SecureStoragePackingChoiceStore.fromStored(
          '{"preferences":[],"slots":["treat"],"treatDays":"friday"}',
        )!.treatDays,
        TreatDays.fridayOnly,
      );
    });
  });
}
