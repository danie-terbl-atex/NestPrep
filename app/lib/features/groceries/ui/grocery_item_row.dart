import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../model/grocery_item.dart';
import '../state/grocery_list_controller.dart';
import 'grocery_item_sheet.dart';

/// One line of the list. The whole row is the tick target, because that is the
/// gesture a person standing in a shop makes; editing is a long press, so the
/// two cannot be confused.
class GroceryItemRow extends StatelessWidget {
  const GroceryItemRow({required this.item, super.key});

  final GroceryItem item;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.read<GroceryListController>();
    final view = context.read<HouseholdView>();
    final addedBy = view.memberById(item.addedBy);

    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(NestRadius.lg),
        onTap: () => controller.toggleBought(item),
        onLongPress: () => showGroceryItemSheet(context: context, item: item),
        child: Padding(
          padding: const EdgeInsets.all(NestSpace.md),
          child: Row(
            children: [
              Semantics(
                checked: item.isBought,
                label: item.name,
                excludeSemantics: true,
                child: Icon(
                  item.isBought
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: item.isBought
                      ? nest.colors.success
                      : nest.colors.outlineStrong,
                  size: NestSize.iconLarge,
                ),
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: nest.text.bodyStrong.copyWith(
                        color: item.isBought
                            ? nest.colors.inkTertiary
                            : nest.colors.ink,
                        decoration: item.isBought
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (_subtitleFor(addedBy) case final subtitle?)
                      Text(
                        subtitle,
                        style: nest.text.caption.copyWith(
                          color: nest.colors.inkTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              if (item.isBought)
                NestButton(
                  label: AppCopy.groceriesUndo,
                  variant: NestButtonVariant.ghost,
                  size: NestButtonSize.small,
                  isExpanded: false,
                  onPressed: () => controller.toggleBought(item),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The quantity if there is one, and who asked for it — a name, never a
  /// colour alone (`FE-13`).
  String? _subtitleFor(Member? addedBy) {
    final quantity = item.quantity?.trim();
    final parts = [
      if (quantity != null && quantity.isNotEmpty) quantity,
      if (addedBy != null) addedBy.displayName,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
