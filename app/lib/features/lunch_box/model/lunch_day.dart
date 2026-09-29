import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import '../../family_profiles/model/allergen.dart';
import '../../family_profiles/model/food_rules.dart';
import 'lunch_box.dart';
import 'lunch_concern.dart';
import 'lunch_feedback.dart';
import 'lunch_item.dart';
import 'lunch_safety.dart';
import 'lunch_slot.dart';

/// One school day of one child's week, with every pick already checked —
/// what a day card renders, so nothing is worked out in a build (`FE-12`).
@immutable
class LunchDay {
  const LunchDay({
    required this.date,
    required this.box,
    required this.concerns,
    required this.feedback,
    required this.isToday,
    required this.hasHappened,
  });

  factory LunchDay.of({
    required CalendarDate date,
    required CalendarDate today,
    required LunchBox box,
    required LunchFeedback? feedback,
    required FoodRules rules,
    required Map<String, LunchItem> library,
  }) => LunchDay(
    date: date,
    box: box,
    feedback: feedback,
    isToday: date == today,
    hasHappened: !date.isAfter(today),
    concerns: {
      for (final (slot, pick) in box.filled)
        slot: LunchSafety.concernsFor(
          name: library[pick.itemId]?.name ?? pick.name,
          // The library's allergens where the item is still there: an item
          // that gained one since it was packed is flagged in every box it
          // is already in (lunch-box ADR-0001).
          allergens: <Allergen>{
            ...pick.knownAllergens,
            ...?library[pick.itemId]?.knownAllergens,
          },
          rules: rules,
        ),
    },
  );

  final CalendarDate date;
  final LunchBox box;

  /// Every filled slot → what is said about it; empty for nothing.
  final Map<LunchSlot, List<LunchConcern>> concerns;
  final LunchFeedback? feedback;
  final bool isToday;

  /// Today or earlier: a day whose box can come home.
  final bool hasHappened;

  List<LunchConcern> concernsAt(LunchSlot slot) => concerns[slot] ?? const [];

  bool isUnsafeAt(LunchSlot slot) =>
      concernsAt(slot).any((concern) => concern.isUnsafe);

  bool get hasUnsafe => LunchSlot.values.any(isUnsafeAt);
}
