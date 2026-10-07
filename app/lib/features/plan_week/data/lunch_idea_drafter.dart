import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/model/lunch_week.dart';
import '../model/lunch_ideas_reply.dart';
import '../model/packing_preference.dart';

/// One shelf of Checkers' lunchbox aisle as the model hears of it
/// (lunch-box ADR-0013): the compartment, the shelf's name and the names of
/// the products NestPrep kept from it — the shop's words, nothing about a
/// child.
typedef AisleShelfNames = ({
  LunchSlot slot,
  String title,
  List<String> products,
});

/// Asks the model for a week's lunch ideas (lunch-box ADR-0012, step 2).
/// Behind an interface so a test decides what comes back without Functions
/// (`FE-20`).
///
/// It writes nothing. The phone sends the week, whose lunches, which
/// compartments and how the parent likes to pack, and what the lunchbox aisle
/// had, never anything about a child; a refusal arrives as an
/// `AppFailure` — `AiFailure` when the model could not help,
/// `PremiumRequiredFailure` without premium, `PlanWeekFailure` for the
/// plan's own reasons.
abstract interface class LunchIdeaDrafter {
  Future<LunchIdeasReply> draft({
    required String householdId,
    required LunchWeek week,
    required Set<String> childIds,
    required PackingChoice packing,
    List<AisleShelfNames> aisle = const [],
  });
}
