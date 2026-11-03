import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/data/secure_storage_lunch_variety_store.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_variety.dart';

import '../../../support/fake_lunch_variety.dart';
import '../../../support/household_fixtures.dart';

/// Which compartments every fill keeps the same all week, on this phone
/// (lunch-box ADR-0028): everything but the main until chosen, remembered,
/// and a tap before the remembered choice is read wins over it.
void main() {
  late FakeLunchVarietyStore store;

  setUp(() => store = FakeLunchVarietyStore());

  test('keeps everything but the main the same until somebody chooses', () {
    final choice = lunchVarietyChoice(Fixtures.householdId, store: store);
    addTearDown(choice.dispose);
    expect(choice.variety, LunchVariety.standard);
    expect(choice.variety.keepsSame(LunchSlot.main), isFalse);
    expect(choice.variety.keepsSame(LunchSlot.fruit), isTrue);
  });

  test('a chip changes the choice and the phone keeps it', () {
    final choice = lunchVarietyChoice(Fixtures.householdId, store: store)
      ..toggle(LunchSlot.fruit)
      ..toggle(LunchSlot.main);
    addTearDown(choice.dispose);
    const kept = LunchVariety({
      LunchSlot.main,
      LunchSlot.veg,
      LunchSlot.snack,
      LunchSlot.treat,
    });
    expect(choice.variety, kept);
    expect(store.kept[Fixtures.householdId], kept);
  });

  test('a remembered choice is taken once read', () async {
    store.kept[Fixtures.householdId] = const LunchVariety({});
    final choice = lunchVarietyChoice(Fixtures.householdId, store: store);
    addTearDown(choice.dispose);
    await pumpEventQueue();
    expect(choice.variety, const LunchVariety({}));
  });

  test('a tap before the remembered choice is read wins over it', () async {
    store.kept[Fixtures.householdId] = const LunchVariety({});
    final choice = lunchVarietyChoice(Fixtures.householdId, store: store)
      ..toggle(LunchSlot.main);
    addTearDown(choice.dispose);
    await pumpEventQueue();
    expect(choice.variety.keepsSame(LunchSlot.main), isTrue);
    expect(choice.variety.keepsSame(LunchSlot.fruit), isTrue);
  });

  test('is stored as compartment names, and names this build does not know '
      'are dropped', () {
    final stored = SecureStorageLunchVarietyStore.toStored(
      LunchVariety.standard,
    );
    expect(stored, '["fruit","veg","snack","treat"]');
    expect(
      SecureStorageLunchVarietyStore.fromStored('["fruit","dessert"]'),
      const LunchVariety({LunchSlot.fruit}),
    );
    expect(SecureStorageLunchVarietyStore.fromStored('not json'), isNull);
    expect(SecureStorageLunchVarietyStore.fromStored('{"a":1}'), isNull);
  });
}
