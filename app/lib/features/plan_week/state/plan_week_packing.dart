import 'dart:async';

import '../../lunch_box/model/lunch_slot.dart';
import '../data/packing_choice_store.dart';
import '../model/packing_preference.dart';

/// The brief's packing choices (step 1 of *Plan my week*): how the parent
/// likes to pack — none until they say — and which compartments get filled —
/// every one until they say, and never none. Remembered on this phone per
/// household, so the next plan opens with them.
final class PlanWeekPacking {
  PlanWeekPacking({
    required this._store,
    required this.householdId,
    required this.onChange,
  });

  final PackingChoiceStore _store;
  final String householdId;
  final void Function() onChange;

  var _preferences = <PackingPreference>{};
  var _slots = {...LunchSlot.values};
  var _isChosen = false;

  Set<PackingPreference> get preferences => Set.unmodifiable(_preferences);
  Set<LunchSlot> get slots => Set.unmodifiable(_slots);

  PackingChoice get choice => (preferences: preferences, slots: slots);

  /// Whether [slot] is the one compartment left, which stays.
  bool isLastSlot(LunchSlot slot) =>
      _slots.length == 1 && _slots.contains(slot);

  /// What this phone kept, unless the parent has chosen since it was asked.
  Future<void> restore() async {
    final kept = await _store.read(householdId);
    if (kept == null || _isChosen) return;
    _preferences = {...kept.preferences};
    _slots = {...kept.slots};
    onChange();
  }

  void togglePreference(PackingPreference preference) {
    if (!_preferences.remove(preference)) _preferences.add(preference);
    _chose();
  }

  void toggleSlot(LunchSlot slot) {
    if (isLastSlot(slot)) return;
    if (!_slots.remove(slot)) _slots.add(slot);
    _chose();
  }

  void _chose() {
    _isChosen = true;
    onChange();
    unawaited(
      _store.write(householdId, (
        preferences: {..._preferences},
        slots: {..._slots},
      )),
    );
  }
}
