import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// What can be done to one thing in the pantry besides a step up or down.
enum LunchPantryAction { topUp, usedUp, remove }

/// One pantry entry's menu: a pack more, used up (ticked off by hand), or
/// out of the pantry altogether (lunch-box ADR-0006).
Future<LunchPantryAction?> showLunchPantryEntryMenu({
  required BuildContext context,
  required String name,
  required bool isUsedUp,
}) => showNestSheet<LunchPantryAction>(
  context: context,
  title: LunchPantryCopy.entryMenuTitle(name),
  builder: (sheetContext) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Option(
        icon: LucideIcons.shoppingCart,
        label: LunchPantryCopy.topUp,
        subtitle: LunchPantryCopy.aPack,
        action: LunchPantryAction.topUp,
      ),
      if (!isUsedUp)
        const _Option(
          icon: LucideIcons.circleCheck,
          label: LunchPantryCopy.markUsedUp,
          action: LunchPantryAction.usedUp,
        ),
      const _Option(
        icon: LucideIcons.circleMinus,
        label: LunchPantryCopy.remove,
        action: LunchPantryAction.remove,
      ),
    ],
  ),
);

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.action,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final LunchPantryAction action;

  @override
  Widget build(BuildContext context) => NestListRow(
    title: label,
    subtitle: subtitle,
    leading: NestIconTile(
      icon: icon,
      size: NestSize.avatarMedium,
      iconSize: NestSize.iconMedium,
    ),
    onTap: () => Navigator.of(context).pop(action),
  );
}
