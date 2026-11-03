import 'package:flutter/foundation.dart';

import 'lunch_slot.dart';

/// The compartments every fill keeps the same all week (lunch-box ADR-0028):
/// once a child's compartment holds something this week, its other empty
/// days get the same, so a bag is used up before another is bought. The
/// rest vary. Kept on this phone per household; nothing about a child.
@immutable
final class LunchVariety {
  const LunchVariety(this.sameAllWeek);

  /// Everything but the main: the same fruit, a different lunch.
  static const standard = LunchVariety({
    LunchSlot.fruit,
    LunchSlot.veg,
    LunchSlot.snack,
    LunchSlot.treat,
  });

  final Set<LunchSlot> sameAllWeek;

  bool keepsSame(LunchSlot slot) => sameAllWeek.contains(slot);

  LunchVariety toggled(LunchSlot slot) => LunchVariety(
    keepsSame(slot) ? sameAllWeek.difference({slot}) : {...sameAllWeek, slot},
  );

  /// The slot names in box order, as `buildLunchWeek`'s `sameAllWeek` and
  /// the phone's store carry them.
  List<String> get names => [
    for (final slot in LunchSlot.values)
      if (keepsSame(slot)) slot.name,
  ];

  /// Names this build does not know are dropped.
  static LunchVariety fromNames(Iterable<Object?> names) => LunchVariety({
    for (final slot in LunchSlot.values)
      if (names.contains(slot.name)) slot,
  });

  @override
  bool operator ==(Object other) =>
      other is LunchVariety && setEquals(other.sameAllWeek, sameAllWeek);

  @override
  int get hashCode => Object.hashAllUnordered(sameAllWeek);
}
