import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_item.dart';
import '../model/lunch_item_draft.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_slot.dart';
import '../model/lunch_suggestions.dart';
import 'lunch_item_sheet.dart';
import 'lunch_suggestion_row.dart';

/// What the picker came back with. Closing it is null — none of these.
sealed class LunchPickerChoice {
  const LunchPickerChoice();
}

final class LunchItemChosen extends LunchPickerChoice {
  const LunchItemChosen(this.item);
  final LunchItem item;
}

final class LunchItemAdded extends LunchPickerChoice {
  const LunchItemAdded(this.draft);
  final LunchItemDraft draft;
}

final class LunchSlotCleared extends LunchPickerChoice {
  const LunchSlotCleared();
}

/// The one-tap swap: a slot's library for one child, best first
/// (lunch-box ADR-0003). What the child does not like is offered below the
/// suggestions; what is not safe for them is shown last and cannot be picked,
/// with the reason on it (lunch-box ADR-0001).
Future<LunchPickerChoice?> showLunchPickerSheet({
  required BuildContext context,
  required LunchSlot slot,
  required String dayName,
  required String childName,
  required RankedLunchItems ranked,
  required LunchPick? current,
}) => showNestSheet<LunchPickerChoice>(
  context: context,
  title: LunchCopy.pickerTitle(slot, dayName),
  builder: (_) => _PickerBody(
    slot: slot,
    childName: childName,
    ranked: ranked,
    current: current,
  ),
);

class _PickerBody extends StatelessWidget {
  const _PickerBody({
    required this.slot,
    required this.childName,
    required this.ranked,
    required this.current,
  });

  final LunchSlot slot;
  final String childName;
  final RankedLunchItems ranked;
  final LunchPick? current;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final isEmpty =
        ranked.suggested.isEmpty &&
        ranked.disliked.isEmpty &&
        ranked.unsafe.isEmpty;
    return ListView(
      shrinkWrap: true,
      children: [
        NestButton(
          label: LunchCopy.somethingElse,
          icon: Icons.add_rounded,
          variant: NestButtonVariant.tonal,
          size: NestButtonSize.medium,
          onPressed: () => _addNew(context),
        ),
        if (current != null) ...[
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: LunchCopy.takeItOut,
            icon: Icons.remove_circle_outline,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.medium,
            onPressed: () =>
                Navigator.of(context).pop(const LunchSlotCleared()),
          ),
        ],
        if (isEmpty) ...[
          const SizedBox(height: NestSpace.lg),
          Text(LunchCopy.libraryEmpty, style: nest.text.bodySecondary),
        ],
        _PickerSection(
          title: LunchCopy.suggestedFor(childName),
          entries: ranked.suggested,
          current: current,
          canPick: true,
        ),
        _PickerSection(
          title: LunchCopy.dislikedBy(childName),
          entries: ranked.disliked,
          current: current,
          canPick: true,
        ),
        _PickerSection(
          title: LunchCopy.notSafeFor(childName),
          entries: ranked.unsafe,
          current: current,
          canPick: false,
        ),
      ],
    );
  }

  Future<void> _addNew(BuildContext context) async {
    final navigator = Navigator.of(context);
    final draft = await showLunchItemSheet(
      context: context,
      fixedSlot: slot,
      confirmLabel: LunchCopy.addAndPack,
    );
    if (draft == null || !navigator.mounted) return;
    navigator.pop(LunchItemAdded(draft));
  }
}

/// One group of the picker — suggested, disliked or not safe — under its
/// heading; nothing at all when the group is empty.
class _PickerSection extends StatelessWidget {
  const _PickerSection({
    required this.title,
    required this.entries,
    required this.current,
    required this.canPick,
  });

  final String title;
  final List<LunchSuggestion> entries;
  final LunchPick? current;
  final bool canPick;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NestSpace.lg),
        NestSectionHeader(title: title),
        const SizedBox(height: NestSpace.xs),
        for (final entry in entries)
          LunchSuggestionRow(
            key: ValueKey(entry.item.id),
            suggestion: entry,
            isCurrent: entry.item.id == current?.itemId,
            onTap: canPick
                ? () => Navigator.of(context).pop(LunchItemChosen(entry.item))
                : null,
          ),
      ],
    );
  }
}
