import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../family_profiles/model/allergen.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'left_out_reason.dart';
import 'lunch_idea.dart';

/// What `draftLunchIdeas` gave back (lunch-box ADR-0012): the model's ideas,
/// already struck out per child by the server, and the household's budget.
@immutable
final class LunchIdeasReply {
  LunchIdeasReply({
    required List<LunchIdea> ideas,
    required this.budgetCents,
    required this.callsLeft,
  }) : ideas = List.unmodifiable(ideas);

  /// The callable's reply, parsed. A reply that is not the contract's shape
  /// is the model's answer arriving unreadable, and is said so — never cast
  /// (`ENG-09`). A single idea that does not parse is left out.
  factory LunchIdeasReply.fromWire(Object? data) {
    if (data case {'ideas': final List<Object?> ideas}) {
      return LunchIdeasReply(
        ideas: [for (final entry in ideas) ?_idea(entry)],
        budgetCents: switch (data['budgetCents']) {
          final int cents when cents > 0 => cents,
          _ => null,
        },
        callsLeft: switch (data['callsLeft']) {
          final int calls => calls,
          _ => null,
        },
      );
    }
    throw const AiFailure(AiProblem.aiUnreadable);
  }

  final List<LunchIdea> ideas;

  /// The household's weekly lunch budget, when one is set.
  final int? budgetCents;

  /// AI calls left this month; null when nothing was asked of the model.
  final int? callsLeft;

  static LunchIdea? _idea(Object? data) {
    if (data
        case {
          'id': final String id,
          'slot': final String slotName,
          'idea': final String idea,
          'searchTerm': final String searchTerm,
          'childIds': final List<Object?> childIds,
        }
        when id.isNotEmpty && idea.trim().isNotEmpty) {
      final slot = LunchSlot.fromName(slotName);
      if (slot == null) return null;
      return LunchIdea(
        id: id,
        slot: slot,
        idea: idea.trim(),
        searchTerm: searchTerm.trim().isEmpty ? idea.trim() : searchTerm.trim(),
        why: switch (data['why']) {
          final String why => why.trim(),
          _ => '',
        },
        childIds: childIds.whereType<String>().toList(),
        excluded: switch (data['excluded']) {
          final List<Object?> excluded => [
            for (final entry in excluded) ?_exclusion(entry),
          ],
          _ => const [],
        },
        origin: IdeaOrigin.drafted,
      );
    }
    return null;
  }

  static LeftOutReason? _exclusion(Object? data) {
    if (data case {
      'childId': final String childId,
      'reason': final String reason,
    }) {
      final allergen = switch (data['allergen']) {
        final String code => Allergen.fromCode(code),
        _ => null,
      };
      return switch (reason) {
        'allergy' when allergen != null => LeftOutReason(
          LeftOutKind.allergy,
          childId: childId,
          allergen: allergen,
        ),
        'allergy' => LeftOutReason(LeftOutKind.otherAllergy, childId: childId),
        'dislike' => LeftOutReason(LeftOutKind.dislike, childId: childId),
        _ => null,
      };
    }
    return null;
  }
}
