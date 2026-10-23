import '../../lunch_box/model/lunch_slot.dart';

/// How a parent likes to pack, chosen in the brief and read by both
/// callables. The names are the wire's, and `PACKING_PREFERENCES` in
/// `functions/src/plan_week/packing_preferences.ts` holds the same in the
/// same order — `packing_preference_test.dart` holds them together.
enum PackingPreference {
  readyMade,
  tenMinutes,
  airFryer,
  nightBefore,
  sundayBatch,
  favourPrice,
  singleServe,
  noFridge,
  healthier,
}

/// The brief's packing choices: how the parent likes to pack, which
/// compartments get filled — never none — and which school days may have a
/// treat (lunch-box ADR-0025; ISO weekdays, possibly none).
typedef PackingChoice = ({
  Set<PackingPreference> preferences,
  Set<LunchSlot> slots,
  Set<int> treatDays,
});

extension PlannedSlots on PackingChoice {
  /// The compartments this plan can fill: the chosen ones, less the treat
  /// when no school day may have one — what the server opens, too.
  Set<LunchSlot> get plannedSlots =>
      treatDays.isEmpty ? slots.difference({LunchSlot.treat}) : slots;
}

/// The [chosen] of [values] by name, in [values]' order — as the wire
/// carries them.
List<String> wireNames<T extends Enum>(List<T> values, Set<T> chosen) => [
  for (final value in values)
    if (chosen.contains(value)) value.name,
];
