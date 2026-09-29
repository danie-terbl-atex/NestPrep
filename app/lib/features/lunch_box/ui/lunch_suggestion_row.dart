import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_suggestion_reasons.dart';
import '../model/lunch_suggestions.dart';
import 'art/lunch_glyph.dart';
import 'lunch_concern_tags.dart';

/// One library item in a slot's picker: its name, why it is where it is in
/// the order — eaten, left, liked, already this week — and anything wrong
/// with it for this child. An unsafe one cannot be tapped; it is shown so the
/// person knows it was left out on purpose (lunch-box ADR-0001).
class LunchSuggestionRow extends StatelessWidget {
  const LunchSuggestionRow({
    required this.suggestion,
    required this.isCurrent,
    required this.onTap,
    super.key,
  });

  final LunchSuggestion suggestion;
  final bool isCurrent;

  /// Null for an item that cannot go in this box.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final item = suggestion.item;
    final slot = item.slot;
    final reasons = suggestionReasons(suggestion);
    return Semantics(
      enabled: onTap != null,
      selected: isCurrent,
      child: NestListRow(
        title: item.name,
        subtitle: reasons.isEmpty ? null : reasons.join(' · '),
        isSelected: isCurrent,
        leading: slot == null
            ? null
            : LunchSlotTile(slot: slot, isEmpty: suggestion.isUnsafe),
        trailing: isCurrent
            ? Icon(
                Icons.check_circle_rounded,
                color: NestTheme.of(context).colors.accent,
                size: NestSize.iconMedium,
              )
            : null,
        footer: suggestion.concerns.isEmpty
            ? null
            : LunchConcernTags(concerns: suggestion.concerns),
        onTap: onTap,
      ),
    );
  }
}

/// The reasons a suggestion ranks where it does, as a person reads them.
List<String> suggestionReasons(LunchSuggestion suggestion) => [
  for (final reason in LunchSuggestionReasons.of(suggestion))
    switch (reason) {
      Eaten(:final times) => LunchCopy.eatenTimes(times),
      Left(:final times) => LunchCopy.leftTimes(times),
      Liked() => LunchCopy.likesIt,
      AlreadyThisWeek(:final times) => LunchCopy.alreadyThisWeek(times),
    },
];
