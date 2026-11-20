import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/grocery_plan_copy.dart';
import '../../assistants/ui/assistant_via_mark.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../model/grocery_item.dart';
import '../state/grocery_list_controller.dart';
import 'grocery_item_sheet.dart';

/// One line of the list. The circle ticks; a tap on the rest of the row does
/// [onTap] when a feature gives one, and ticks too when none does. Editing is
/// a long press, so the two cannot be confused (groceries ADR-0009).
///
/// Another feature can add to a row without the row knowing it: [trailing]
/// sits beside the name, and [footer] below it, outside the tick target so a
/// tap there never ticks the item (the Checkers product matches use both).
class GroceryItemRow extends StatelessWidget {
  const GroceryItemRow({
    required this.item,
    this.onTap,
    this.trailing,
    this.footer,
    super.key,
  });

  final GroceryItem item;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.read<GroceryListController>();
    final view = context.read<HouseholdView>();
    final addedBy = view.memberById(item.addedBy);
    final canEdit = view.permissions.canEdit(HouseholdArea.groceries);

    final below = footer;
    final tick = canEdit ? () => controller.toggleBought(item) : null;
    final row = InkWell(
      borderRadius: BorderRadius.circular(NestRadius.lg),
      onTap: canEdit ? onTap ?? tick : null,
      onLongPress: canEdit
          ? () => showGroceryItemSheet(context: context, item: item)
          : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: NestSpace.md),
        child: Row(
          children: [
            Semantics(
              checked: item.isBought,
              label: item.name,
              excludeSemantics: true,
              onTap: tick,
              child: InkResponse(
                key: ValueKey('grocery-tick-${item.id}'),
                onTap: tick,
                radius: NestSize.touchTarget / 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: NestSize.touchTarget,
                    minHeight: NestSize.touchTarget,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(NestSpace.md),
                    child: Icon(
                      item.isBought
                          ? LucideIcons.circleCheck
                          : LucideIcons.circle,
                      color: item.isBought
                          ? nest.colors.success
                          : nest.colors.outlineStrong,
                      size: NestSize.iconLarge,
                    ),
                  ),
                ),
              ),
            ),
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
                  if (item.addedVia case final via?) ...[
                    const SizedBox(height: NestSpace.xxs),
                    AssistantViaMark(via: via),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (item.isBought && canEdit)
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
    );
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: below == null
          ? row
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row,
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    NestSpace.md,
                    0,
                    NestSpace.md,
                    NestSpace.md,
                  ),
                  child: below,
                ),
              ],
            ),
    );
  }

  /// The quantity if there is one, and who asked for it — a name, never a
  /// colour alone (`FE-13`). An item the plans put here says which plans
  /// instead: *For 5 lunches + Tuesday dinner* (groceries ADR-0002).
  String? _subtitleFor(Member? addedBy) {
    final quantity = item.quantity?.trim();
    final source = item.isFromPlans
        ? item.sourceNote ?? GroceryPlanCopy.fromPlans
        : null;
    final parts = [
      if (quantity != null && quantity.isNotEmpty) quantity,
      if (source != null) source else if (addedBy != null) addedBy.displayName,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
