import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_pantry_week.dart';
import 'art/lunch_glyph.dart';
import 'lunch_portion_stepper.dart';

/// One thing in the pantry: how many boxes it is enough for, what this week
/// still needs of it, and — for somebody who may change it — a stepper and a
/// tap for the rest (lunch-box ADR-0006).
class LunchPantryRow extends StatelessWidget {
  const LunchPantryRow({
    required this.line,
    required this.onPortions,
    required this.onMore,
    super.key,
  });

  final LunchPantryLine line;

  /// Null for somebody who may only look.
  final ValueChanged<int>? onPortions;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final item = line.item;
    final slot = item.slot;
    final onPortions = this.onPortions;
    return NestListRow(
      title: item.name,
      subtitle: [
        LunchPantryCopy.enoughFor(line.portions),
        if (line.stillToPack > 0) LunchPantryCopy.weekTakes(line.stillToPack),
      ].join(' · '),
      leading: slot == null
          ? null
          : LunchSlotTile(slot: slot, isEmpty: line.entry.isUsedUp),
      trailing: onPortions == null
          ? null
          : LunchPortionStepper(
              name: item.name,
              portions: line.portions,
              onChanged: onPortions,
            ),
      footer: line.isShort
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestTag(
                label: LunchPantryCopy.short(-line.available),
                tone: NestTagTone.warning,
                icon: Icons.shopping_basket_outlined,
              ),
            )
          : null,
      onTap: onMore,
    );
  }
}
