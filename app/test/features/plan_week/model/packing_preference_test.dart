import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/data/secure_storage_packing_choice_store.dart';
import 'package:nestprep/features/plan_week/model/packing_preference.dart';

/// The packing preferences are one list in two languages: the phone sends
/// the names, the Function reads them.
void main() {
  test('are the same names, in the same order, as the server holds', () {
    final server = File(
      '../functions/src/plan_week/packing_preferences.ts',
    ).readAsStringSync();
    final literal = RegExp(
      r'PACKING_PREFERENCES = \[([^\]]*)\]',
    ).firstMatch(server)!;
    final names = RegExp(
      "'([^']*)'",
    ).allMatches(literal.group(1)!).map((name) => name.group(1)).toList();
    expect(names, [for (final value in PackingPreference.values) value.name]);
  });

  group('kept on the phone', () {
    test('comes back as it was chosen', () {
      const PackingChoice choice = (
        preferences: {PackingPreference.airFryer, PackingPreference.healthier},
        slots: {LunchSlot.main, LunchSlot.snack},
      );
      final back = SecureStoragePackingChoiceStore.fromStored(
        SecureStoragePackingChoiceStore.toStored(choice),
      )!;
      expect(back.preferences, choice.preferences);
      expect(back.slots, choice.slots);
    });

    test('drops names this build does not know, and is no choice with no '
        'compartment or unreadable', () {
      final back = SecureStoragePackingChoiceStore.fromStored(
        '{"preferences":["airFryer","jetpack"],"slots":["fruit","lid"]}',
      )!;
      expect(back.preferences, {PackingPreference.airFryer});
      expect(back.slots, {LunchSlot.fruit});
      expect(
        SecureStoragePackingChoiceStore.fromStored('{"slots":[]}'),
        isNull,
      );
      expect(SecureStoragePackingChoiceStore.fromStored('not json'), isNull);
    });
  });
}
