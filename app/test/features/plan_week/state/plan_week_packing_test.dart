import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/packing_preference.dart';
import 'package:nestprep/features/plan_week/state/plan_week_packing.dart';

import '../../../support/fake_plan_week.dart';
import '../../../support/household_fixtures.dart';

/// The brief's packing choices: every compartment and no preference until
/// the parent says, never no compartment, and remembered on the phone.
void main() {
  late FakePackingChoiceStore store;
  late int changes;

  PlanWeekPacking packing() => PlanWeekPacking(
    store: store,
    householdId: Fixtures.householdId,
    onChange: () => changes++,
  );

  setUp(() {
    store = FakePackingChoiceStore();
    changes = 0;
  });

  test('start as every compartment and no preference, never lose the last '
      'compartment, and are kept on the phone', () async {
    final choices = packing();
    expect(choices.slots, {...LunchSlot.values});
    expect(choices.preferences, isEmpty);
    for (final slot in LunchSlot.values) {
      choices.toggleSlot(slot);
    }
    expect(choices.slots, {LunchSlot.treat});
    expect(choices.isLastSlot(LunchSlot.treat), isTrue);
    choices
      ..toggleSlot(LunchSlot.main)
      ..togglePreference(PackingPreference.airFryer)
      ..togglePreference(PackingPreference.noFridge)
      ..togglePreference(PackingPreference.noFridge);
    await pumpEventQueue();
    final kept = store.kept[Fixtures.householdId]!;
    expect(kept.slots, {LunchSlot.main, LunchSlot.treat});
    expect(kept.preferences, {PackingPreference.airFryer});
    expect(changes, greaterThan(0));
  });

  test('come back on the next visit, or are the defaults when they cannot '
      'be read', () async {
    store.kept[Fixtures.householdId] = (
      preferences: {PackingPreference.healthier},
      slots: {LunchSlot.fruit},
    );
    final next = packing();
    await next.restore();
    expect(next.slots, {LunchSlot.fruit});
    expect(next.preferences, {PackingPreference.healthier});

    store.failRead = true;
    final unread = packing();
    await unread.restore();
    expect(unread.slots, {...LunchSlot.values});
  });

  test('a choice made before the phone answers is not overwritten', () async {
    store.kept[Fixtures.householdId] = (
      preferences: const {},
      slots: {LunchSlot.fruit},
    );
    final choices = packing();
    final restoring = choices.restore();
    choices.togglePreference(PackingPreference.favourPrice);
    await restoring;
    expect(choices.slots, {...LunchSlot.values});
    expect(choices.preferences, {PackingPreference.favourPrice});
  });
}
