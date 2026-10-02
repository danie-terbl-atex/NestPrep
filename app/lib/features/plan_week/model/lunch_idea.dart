import 'package:flutter/foundation.dart';

import '../../family_profiles/model/food_rules.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'allergen_words.dart';
import 'food_text_check.dart';
import 'left_out_reason.dart';

/// Where an idea on the list came from, for the list to say.
enum IdeaOrigin {
  /// The model drafted it.
  drafted,

  /// The household's own library — ideas without AI (lunch-box ADR-0012 §6).
  usual,

  /// A parent typed it.
  own,

  /// A shelf of Checkers' own Kids Lunchbox aisle, read before any idea was
  /// drafted and already answered (lunch-box ADR-0013).
  aisle,
}

/// One thing to look for at the shop, for one compartment (lunch-box
/// ADR-0012): what it is, what to search, why, which children it is for, and
/// for which it was struck out and why.
@immutable
final class LunchIdea {
  LunchIdea({
    required this.id,
    required this.slot,
    required this.idea,
    required this.searchTerm,
    required this.why,
    required List<String> childIds,
    required List<LeftOutReason> excluded,
    required this.origin,
  }) : childIds = List.unmodifiable(childIds),
       excluded = List.unmodifiable(excluded);

  /// An idea checked on the phone against each child's rules — one a parent
  /// typed, or one from the library — the same way the server checks the
  /// model's.
  factory LunchIdea.checked({
    required String id,
    required LunchSlot slot,
    required String idea,
    required Map<String, FoodRules> rulesByChild,
    required IdeaOrigin origin,
    String? searchTerm,
    String why = '',
  }) {
    final allergens = AllergenWords.mentionedIn(idea);
    final childIds = <String>[];
    final excluded = <LeftOutReason>[];
    for (final MapEntry(key: childId, value: rules) in rulesByChild.entries) {
      final reason = FoodTextCheck.reasonFor(
        childId: childId,
        name: idea,
        allergens: allergens,
        rules: rules,
      );
      if (reason == null) {
        childIds.add(childId);
      } else {
        excluded.add(reason);
      }
    }
    return LunchIdea(
      id: id,
      slot: slot,
      idea: idea,
      searchTerm: searchTerm ?? idea,
      why: why,
      childIds: childIds,
      excluded: excluded,
      origin: origin,
    );
  }

  static const textLimit = 60;

  final String id;
  final LunchSlot slot;
  final String idea;
  final String searchTerm;

  /// The model's reason, or empty.
  final String why;

  /// The children it is still for.
  final List<String> childIds;

  /// For whom NestPrep struck it out, and why.
  final List<LeftOutReason> excluded;
  final IdeaOrigin origin;

  /// Struck out for every child: shown, never searched.
  bool get isStruckOut => childIds.isEmpty;
}
