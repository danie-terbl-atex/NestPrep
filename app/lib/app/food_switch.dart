import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/nest_kit.dart';
import '../features/household/model/household_area.dart';
import '../features/household/model/household_permissions.dart';
import '../features/household/model/household_view.dart';
import 'household_shell.dart';

/// Lunch and Meals under the Food tab, side by side (design-system
/// ADR-0017), the way [ListsSwitch] holds the two lists. Nothing at all for
/// somebody who may use only one of them.
class FoodSwitch extends StatelessWidget {
  const FoodSwitch({required this.current, required this.onSelect, super.key});

  final HouseholdTab current;
  final ValueChanged<HouseholdTab> onSelect;

  static bool isShownTo(HouseholdPermissions permissions) =>
      permissions.canUse(HouseholdArea.lunch) &&
      permissions.canUse(HouseholdArea.meals);

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
          for (final tab in const [HouseholdTab.lunch, HouseholdTab.meals])
            NestChip(
              label: tab.label,
              icon: tab.icon,
              isSelected: tab == current,
              onTap: () => onSelect(tab),
            ),
        ],
      ),
    );
  }
}
