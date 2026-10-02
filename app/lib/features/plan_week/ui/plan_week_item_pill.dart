import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../lunch_box/model/lunch_slot.dart';
import '../../lunch_box/ui/art/lunch_glyph.dart';
import '../model/shop_week.dart';

/// How a compartment stands on the review.
enum PillLook {
  /// Packed before the plan — quiet, and not the plan's to change.
  existing,

  /// What the plan adds — the slot's pastel, and a tap swaps it.
  added,

  /// Nothing there, and the plan left it — a tap fills it.
  empty,
}

/// One compartment on the review: the slot's little drawing and what is in
/// it — the money is the basket's, in whole packs. The glyph is decoration; the words
/// carry the meaning, and the slot and where the pick came from are read
/// out with them (`FE-13`).
class PlanWeekItemPill extends StatelessWidget {
  const PlanWeekItemPill({
    required this.slot,
    required this.look,
    this.name,
    this.origin,
    this.onTap,
    super.key,
  });

  final LunchSlot slot;
  final PillLook look;
  final String? name;
  final PickOrigin? origin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final colors = nest.colors;
    final label = name ?? LunchCopy.addToSlot(slot);
    final background = switch (look) {
      PillLook.added => slotFill(colors, slot),
      PillLook.existing => colors.surfaceTint,
      PillLook.empty => colors.surface,
    };
    final color = switch (look) {
      PillLook.added => colors.ink,
      PillLook.existing => colors.inkSecondary,
      PillLook.empty => colors.inkTertiary,
    };
    return Semantics(
      button: onTap != null,
      label: [
        LunchCopy.slotName(slot),
        label,
        switch (look) {
          PillLook.existing => PlanWeekCopy.alreadyPacked,
          PillLook.added => _originWords(origin),
          PillLook.empty => '',
        },
      ].where((part) => part.isNotEmpty).join(', '),
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NestRadius.pill),
          side: look == PillLook.empty
              ? BorderSide(color: colors.outline)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: NestSize.touchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NestSpace.md,
                vertical: NestSpace.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: look == PillLook.added ? 1 : 0.55,
                    child: LunchGlyph(slot: slot, size: NestSize.iconMedium),
                  ),
                  const SizedBox(width: NestSpace.sm),
                  Flexible(
                    child: Text(
                      label,
                      style: nest.text.label.copyWith(color: color),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (look == PillLook.added &&
                      origin == PickOrigin.swapped) ...[
                    const SizedBox(width: NestSpace.xs),
                    Icon(
                      Icons.edit_rounded,
                      size: NestSize.iconBadge,
                      color: colors.inkSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _originWords(PickOrigin? origin) => switch (origin) {
    PickOrigin.suggested => PlanWeekCopy.originSuggested,
    PickOrigin.filled => PlanWeekCopy.originFilled,
    PickOrigin.swapped => PlanWeekCopy.originSwapped,
    null => '',
  };
}
