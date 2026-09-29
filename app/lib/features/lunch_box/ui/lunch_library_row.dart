import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_item.dart';
import '../state/lunch_board_controller.dart';
import 'art/lunch_glyph.dart';
import 'lunch_item_sheet.dart';

/// One library item: its name, what is in it, whether it is a Sunday-prep
/// thing, and a way to put it away or bring it back.
class LunchLibraryRow extends StatelessWidget {
  const LunchLibraryRow({required this.item, required this.canEdit, super.key});

  final LunchItem item;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final slot = item.slot;
    final allergens = [
      for (final allergen in item.knownAllergens)
        FamilyCopy.allergenName(allergen).toLowerCase(),
    ];
    return NestListRow(
      title: item.name,
      subtitle: allergens.isEmpty ? null : LunchCopy.contains(allergens),
      leading: slot == null
          ? null
          : LunchSlotTile(slot: slot, isEmpty: item.archived),
      footer: item.prepAhead
          ? const Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestTag(
                label: LunchCopy.prepAheadTag,
                tone: NestTagTone.accent,
                icon: Icons.soup_kitchen_outlined,
              ),
            )
          : null,
      // An icon, not a word: a row at 200% text on a phone has no room for
      // a button beside its name (`FE-14`). The label says it to a screen
      // reader and on a long press.
      trailing: canEdit
          ? NestIconButton(
              icon: item.archived
                  ? Icons.unarchive_outlined
                  : Icons.inventory_2_outlined,
              label: item.archived
                  ? LunchCopy.bringBack(item.name)
                  : LunchCopy.putAway(item.name),
              variant: NestIconButtonVariant.plain,
              onPressed: () => context
                  .read<LunchBoardController>()
                  .edit
                  .setArchived(item.id, archived: !item.archived),
            )
          : null,
      onTap: canEdit ? () => _edit(context) : null,
    );
  }

  Future<void> _edit(BuildContext context) async {
    final controller = context.read<LunchBoardController>();
    final draft = await showLunchItemSheet(context: context, existing: item);
    if (draft == null) return;
    await controller.edit.updateItem(item, draft);
  }
}
