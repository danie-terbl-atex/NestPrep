import 'package:flutter/foundation.dart';

import '../../family_profiles/model/food_rules.dart';
import 'lunch_concern.dart';
import 'lunch_item.dart';
import 'lunch_safety.dart';
import 'lunch_slot.dart';
import 'lunch_taste.dart';

/// One library item as the picker offers it to one child: ranked, and with
/// everything that is said about it.
@immutable
class LunchSuggestion {
  const LunchSuggestion({
    required this.item,
    required this.taste,
    required this.concerns,
    required this.isLiked,
    required this.usesThisWeek,
    required this.score,
  });

  final LunchItem item;
  final ItemTaste taste;
  final List<LunchConcern> concerns;

  /// It matches one of the child's likes.
  final bool isLiked;

  /// How many boxes already hold it this week.
  final int usesThisWeek;

  /// What ranks it: see `LunchSuggestions`.
  final double score;

  bool get isUnsafe => concerns.any((concern) => concern.isUnsafe);

  bool get isDisliked => concerns.any((concern) => concern is DislikeConcern);
}

/// A slot's library split three ways for one child (lunch-box ADR-0003).
@immutable
class RankedLunchItems {
  const RankedLunchItems({
    required this.suggested,
    required this.disliked,
    required this.unsafe,
  });

  /// Safe and not disliked, best first — what auto-fill takes from.
  final List<LunchSuggestion> suggested;

  /// Safe, but the child said no. Offered, never suggested.
  final List<LunchSuggestion> disliked;

  /// Refused by the rules for this child. Shown, and cannot be picked.
  final List<LunchSuggestion> unsafe;

  LunchSuggestion? get best => suggested.firstOrNull;
}

/// How the picker and auto-fill order a slot's items for one child — the
/// taste score from `LunchTaste`, plus two nudges, and nothing hidden:
///
/// - **+2** when it matches one of the child's likes;
/// - **−3** for each box already holding it this week, so a week has variety
///   without anybody asking for it;
/// - ties go to the name, alphabetically, so the order never shuffles.
///
/// Unsafe items and disliked items are never suggested.
abstract final class LunchSuggestions {
  static const likeBonus = 2.0;
  static const repeatPenalty = 3.0;

  static RankedLunchItems rank({
    required LunchSlot slot,
    required Iterable<LunchItem> library,
    required FoodRules rules,
    required LunchTaste taste,
    Map<String, int> usesThisWeek = const {},
  }) {
    final all = [
      for (final item in library)
        if (!item.archived && item.slot == slot)
          suggestionFor(
            item,
            rules: rules,
            taste: taste,
            uses: usesThisWeek[item.id] ?? 0,
          ),
    ]..sort(byRank);
    return RankedLunchItems(
      suggested: [
        for (final entry in all)
          if (!entry.isUnsafe && !entry.isDisliked) entry,
      ],
      disliked: [
        for (final entry in all)
          if (!entry.isUnsafe && entry.isDisliked) entry,
      ],
      unsafe: [
        for (final entry in all)
          if (entry.isUnsafe) entry,
      ],
    );
  }

  static LunchSuggestion suggestionFor(
    LunchItem item, {
    required FoodRules rules,
    required LunchTaste taste,
    int uses = 0,
  }) {
    final itemTaste = taste.of(item.id);
    final isLiked = rules.likes.any(
      (like) => LunchSafety.mentions(item.name, like),
    );
    return LunchSuggestion(
      item: item,
      taste: itemTaste,
      concerns: LunchSafety.concernsFor(
        name: item.name,
        allergens: item.knownAllergens,
        rules: rules,
      ),
      isLiked: isLiked,
      usesThisWeek: uses,
      score: itemTaste.score + (isLiked ? likeBonus : 0) - uses * repeatPenalty,
    );
  }

  static int byRank(LunchSuggestion a, LunchSuggestion b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byName = a.item.nameKey.compareTo(b.item.nameKey);
    return byName != 0 ? byName : a.item.id.compareTo(b.item.id);
  }
}
