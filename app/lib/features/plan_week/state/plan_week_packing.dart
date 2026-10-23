import 'dart:async';

import '../../lunch_box/model/lunch_slot.dart';
import '../data/packing_choice_store.dart';
import '../model/packing_preference.dart';
import '../model/treat_days.dart';

/// The brief's packing choices (step 1 of *Plan my week*): how the parent
/// likes to pack — none until they say — which compartments get filled —
/// every one until they say, and never none — and which school days get a
/// treat — Friday until they say, and possibly none (lunch-box ADR-0025).
/// Remembered on this phone per household, so the next plan opens with them.
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
  var _treatDays = {...TreatDays.fridayOnly};
  var _isChosen = false;

  Set<PackingPreference> get preferences => Set.unmodifiable(_preferences);
  Set<LunchSlot> get slots => Set.unmodifiable(_slots);
  Set<int> get treatDays => Set.unmodifiable(_treatDays);

  /// Whether the treat compartment is filled at all; treat days mean
  /// nothing without it.
  bool get hasTreats => _slots.contains(LunchSlot.treat);

  PackingChoice get choice =>
      (preferences: preferences, slots: slots, treatDays: treatDays);

  /// The compartments this plan can fill ([PlannedSlots.plannedSlots]).
  Set<LunchSlot> get plannedSlots => choice.plannedSlots;

  /// Whether [slot] is the one compartment left, which stays.
  bool isLastSlot(LunchSlot slot) =>
      _slots.length == 1 && _slots.contains(slot);

  /// What this phone kept, unless the parent has chosen since it was asked.
  Future<void> restore() async {
    final kept = await _store.read(householdId);
    if (kept == null || _isChosen) return;
    _preferences = {...kept.preferences};
    _slots = {...kept.slots};
    _treatDays = {...kept.treatDays};
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

  /// One school day on or off — zero days is allowed and plans no treat.
  void toggleTreatDay(int isoWeekday) {
    if (!TreatDays.schoolDays.contains(isoWeekday)) return;
    if (!_treatDays.remove(isoWeekday)) _treatDays.add(isoWeekday);
    _chose();
  }

  /// A shortcut's days, in place of whatever was chosen.
  void chooseTreatDays(Set<int> days) {
    _treatDays = TreatDays.schoolDaysIn(days);
    _chose();
  }

  void _chose() {
    _isChosen = true;
    onChange();
    unawaited(
      _store.write(householdId, (
        preferences: {..._preferences},
        slots: {..._slots},
        treatDays: {..._treatDays},
      )),
    );
  }
}
