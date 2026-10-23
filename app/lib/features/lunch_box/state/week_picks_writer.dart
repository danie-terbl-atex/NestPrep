import '../../../shared/failure/app_failure.dart';
import '../data/lunch_repository.dart';
import '../model/lunch_board.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_safety.dart';
import '../model/lunch_week.dart';

/// What one write of a planned week did.
typedef WrittenPicks = ({int lunches, int skipped});

/// Writes a planned week — *Plan my week*'s, or *Fill the week*'s
/// (lunch-box ADR-0020) — into each child's plan, through the same
/// repository and rules as packing a box by hand: never into a
/// compartment somebody packed meanwhile, never anything no longer safe for
/// the child, and one school day per write (lunch-box ADR-0010, inside
/// `setPicks`).
final class WeekPicksWriter {
  WeekPicksWriter({
    required LunchRepository lunchRepository,
    required this.householdId,
  }) : _lunches = lunchRepository;

  final LunchRepository _lunches;
  final String householdId;

  /// [picksByChild] is child id → slot key → the pick.
  Future<WrittenPicks> write({
    required LunchBoard board,
    required LunchWeek week,
    required Map<String, Map<String, LunchPick>> picksByChild,
  }) async {
    var lunches = 0;
    var skipped = 0;
    for (final MapEntry(key: childId, value: planned) in picksByChild.entries) {
      final now = board.childWeek(childId);
      if (now == null) {
        skipped += planned.length;
        continue;
      }
      final picks = <String, LunchPick>{
        for (final MapEntry(:key, value: pick) in planned.entries)
          if (!now.plan.slots.containsKey(key) &&
              LunchSafety.isSafe(
                allergens: pick.knownAllergens,
                rules: now.child.foodRules,
              ))
            key: pick,
      };
      skipped += planned.length - picks.length;
      if (picks.isEmpty) continue;
      try {
        await _lunches.setPicks(
          householdId: householdId,
          childId: childId,
          week: week,
          picks: picks,
        );
        lunches += picks.length;
      } on PermissionDeniedFailure {
        // The rules said no — the child's rules changed on another phone.
        // The other children's weeks still go in.
        skipped += picks.length;
      }
    }
    return (lunches: lunches, skipped: skipped);
  }
}
