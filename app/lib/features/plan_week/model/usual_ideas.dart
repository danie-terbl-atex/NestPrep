import '../../family_profiles/model/food_rules.dart';
import '../../lunch_box/model/lunch_board.dart';
import '../../lunch_box/model/lunch_item.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'lunch_idea.dart';

/// Ideas without AI (lunch-box ADR-0012 §6): the household's own library,
/// ranked for each chosen child as the picker ranks it (lunch-box ADR-0003),
/// the best few per compartment the brief fills — then checked like any
/// other idea.
abstract final class UsualIdeas {
  /// Ideas per compartment: enough to vary a week, few enough to search.
  static const perSlot = 3;

  static List<LunchIdea> from(
    LunchBoard board,
    Set<String> childIds,
    Set<LunchSlot> slots,
  ) {
    final children = [
      for (final childWeek in board.children)
        if (childIds.contains(childWeek.childId)) childWeek,
    ];
    final rulesByChild = <String, FoodRules>{
      for (final childWeek in children)
        childWeek.childId: childWeek.child.foodRules,
    };
    final ideas = <LunchIdea>[];
    for (final slot in LunchSlot.values.where(slots.contains)) {
      final chosen = <String, LunchItem>{};
      for (var rank = 0; chosen.length < perSlot; rank++) {
        var anyLeft = false;
        for (final childWeek in children) {
          final suggested = childWeek.rank(slot, board.library).suggested;
          if (rank >= suggested.length) continue;
          anyLeft = true;
          final item = suggested[rank].item;
          if (chosen.length < perSlot) {
            chosen.putIfAbsent(item.nameKey, () => item);
          }
        }
        if (!anyLeft) break;
      }
      for (final item in chosen.values) {
        ideas.add(
          LunchIdea.checked(
            id: 'usual-${item.id}',
            slot: slot,
            idea: item.name,
            rulesByChild: rulesByChild,
            origin: IdeaOrigin.usual,
          ),
        );
      }
    }
    return ideas;
  }
}
