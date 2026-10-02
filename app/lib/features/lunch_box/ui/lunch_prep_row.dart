import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_prep_list.dart';
import 'art/lunch_glyph.dart';

/// One line of the prep list: the thing, how many boxes it goes in, how to
/// make it ahead, and a tick for when it is ready.
class LunchPrepRowTile extends StatelessWidget {
  const LunchPrepRowTile({
    required this.row,
    required this.onToggle,
    super.key,
  });

  final LunchPrepRow row;

  /// Null for somebody who may only look.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final item = row.item;
    final slot = item.slot;
    final note = item.prepNote;
    return Semantics(
      checked: row.isDone,
      label: LunchCopy.prepRowLabel(item.name, row.isDone),
      excludeSemantics: true,
      button: onToggle != null,
      onTap: onToggle,
      child: NestListRow(
        title: item.name,
        subtitle: [LunchCopy.portions(item.portions), ?note].join(' · '),
        leading: slot == null ? null : LunchSlotTile(slot: slot),
        trailing: Icon(
          row.isDone ? LucideIcons.circleCheck : LucideIcons.circle,
          color: row.isDone ? c.success : c.outlineStrong,
          size: NestSize.iconLarge,
        ),
        onTap: onToggle,
      ),
    );
  }
}
