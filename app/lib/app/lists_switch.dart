import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_permissions.dart';
import '../features/household/model/household_view.dart';
import '../shared/copy/app_copy.dart';
import 'household_shell.dart';

/// The two lists under the Lists tab, side by side (design-system ADR-0009).
/// Nothing at all for somebody who may use only one of them.
class ListsSwitch extends StatelessWidget {
  const ListsSwitch({required this.current, required this.onSelect, super.key});

  final HouseholdTab current;
  final ValueChanged<HouseholdTab> onSelect;

  static bool isShownTo(HouseholdPermissions permissions) =>
      permissions.canUse(HouseholdArea.todos) &&
      permissions.canUse(HouseholdArea.groceries);

  /// The screen's title: "Lists" above the switch, the list's own name
  /// without it.
  static String titleFor(HouseholdPermissions permissions, String own) =>
      isShownTo(permissions) ? AppCopy.tabLists : own;

  @override
  Widget build(BuildContext context) {
    if (!isShownTo(context.watch<HouseholdView>().permissions)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: Wrap(
        spacing: NestSpace.sm,
        runSpacing: NestSpace.sm,
        children: [
          for (final (tab, icon) in [
            (HouseholdTab.todos, LucideIcons.circleCheck),
            (HouseholdTab.groceries, LucideIcons.shoppingBasket),
          ])
            NestChip(
              label: tab == HouseholdTab.todos
                  ? AppCopy.tabTodos
                  : AppCopy.tabGroceries,
              icon: icon,
              isSelected: tab == current,
              onTap: () => onSelect(tab),
            ),
        ],
      ),
    );
  }
}
