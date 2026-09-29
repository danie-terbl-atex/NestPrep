import 'package:flutter/foundation.dart';

import 'lunch_pick.dart';
import 'lunch_slot.dart';

/// One day's box: what is in each of the five compartments, or null for an
/// empty one. The shape a kid's tablet, a favourite and the board all read.
@immutable
class LunchBox {
  LunchBox(Map<LunchSlot, LunchPick?> picks)
    : picks = Map.unmodifiable({
        for (final slot in LunchSlot.values) slot: picks[slot],
      });

  final Map<LunchSlot, LunchPick?> picks;

  LunchPick? operator [](LunchSlot slot) => picks[slot];

  bool get isEmpty => picks.values.every((pick) => pick == null);

  int get filledCount => picks.values.whereType<LunchPick>().length;

  /// The compartments with something in them, in packing order.
  List<(LunchSlot, LunchPick)> get filled => [
    for (final slot in LunchSlot.values)
      if (picks[slot] case final pick?) (slot, pick),
  ];

  @override
  bool operator ==(Object other) =>
      other is LunchBox && mapEquals(other.picks, picks);

  @override
  int get hashCode => Object.hashAll(picks.values);
}
