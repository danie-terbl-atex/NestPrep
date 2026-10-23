import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_concern.dart';
import '../model/lunch_feedback.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_slot.dart';
import 'art/lunch_glyph.dart';
import 'lunch_concern_tags.dart';

/// One compartment of a day's box: its drawing, its name, what is in it —
/// or an invitation to fill it — and anything wrong with it for this child.
/// The whole row is the tap that swaps it (lunch-box ADR-0001); an item made
/// from a recipe adds *How to make it* beside it, its own button and its own
/// node, so the swap is never what a recipe tap does (lunch-box ADR-0021 §8).
class LunchSlotRow extends StatelessWidget {
  const LunchSlotRow({
    required this.slot,
    required this.pick,
    required this.concerns,
    required this.verdict,
    required this.onTap,
    this.onRecipe,
    super.key,
  });

  final LunchSlot slot;
  final LunchPick? pick;
  final List<LunchConcern> concerns;

  /// How it came home, once somebody has said.
  final LunchVerdict? verdict;

  /// Null for somebody who may only look.
  final VoidCallback? onTap;

  /// Opens the recipe the packed item is made from; null when it has none.
  final VoidCallback? onRecipe;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final packed = pick;
    final slotName = LunchCopy.slotName(slot);
    // One node to a screen reader — the slot, what is in it and every
    // concern — so a warning is never left out of what is heard (`FE-13`).
    final row = MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: InkWell(
          borderRadius: BorderRadius.circular(NestRadius.sm),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: NestSize.controlMedium,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
              child: Row(
                children: [
                  LunchSlotTile(slot: slot, isEmpty: packed == null),
                  const SizedBox(width: NestSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slotName,
                          style: nest.text.caption.copyWith(
                            color: c.inkTertiary,
                          ),
                        ),
                        Text(
                          packed?.name ?? LunchCopy.addToSlot(slot),
                          style: packed == null
                              ? nest.text.body.copyWith(color: c.inkTertiary)
                              : nest.text.bodyStrong,
                        ),
                        if (concerns.isNotEmpty) ...[
                          const SizedBox(height: NestSpace.xs),
                          LunchConcernTags(concerns: concerns),
                        ],
                      ],
                    ),
                  ),
                  if (verdict != null) _VerdictMark(verdict: verdict!),
                  if (onTap != null)
                    Icon(
                      packed == null
                          ? LucideIcons.plus
                          : LucideIcons.arrowLeftRight,
                      size: NestSize.iconSmall,
                      color: c.inkTertiary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final openRecipe = onRecipe;
    if (packed == null || openRecipe == null) return row;
    return Row(
      children: [
        Expanded(child: row),
        NestIconButton(
          icon: LucideIcons.chefHat,
          label: RecipeCopy.howToMake(packed.name),
          variant: NestIconButtonVariant.plain,
          onPressed: openRecipe,
        ),
      ],
    );
  }
}

class _VerdictMark extends StatelessWidget {
  const _VerdictMark({required this.verdict});

  final LunchVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final ate = verdict == LunchVerdict.ate;
    return Padding(
      padding: const EdgeInsets.only(right: NestSpace.sm),
      child: Semantics(
        label: ate ? LunchCopy.ateIt : LunchCopy.leftIt,
        child: Icon(
          ate ? LucideIcons.thumbsUp : LucideIcons.thumbsDown,
          size: NestSize.iconSmall,
          color: ate ? c.success : c.warning,
        ),
      ),
    );
  }
}
