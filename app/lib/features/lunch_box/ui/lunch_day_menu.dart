import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// What can be done to a whole day's box.
enum LunchDayAction { saveFavourite, packFavourite, clear }

/// The day's menu: keep this box as a go-to, pack a go-to into it, or empty
/// it. Saving and emptying are offered only for a box with something in it.
Future<LunchDayAction?> showLunchDayMenu({
  required BuildContext context,
  required String dayName,
  required bool hasBox,
}) => showNestSheet<LunchDayAction>(
  context: context,
  title: dayName,
  builder: (sheetContext) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (hasBox)
        const _Option(
          icon: LucideIcons.heart,
          label: LunchCopy.saveAsFavourite,
          action: LunchDayAction.saveFavourite,
        ),
      const _Option(
        icon: LucideIcons.refreshCw,
        label: LunchCopy.packFavourite,
        action: LunchDayAction.packFavourite,
      ),
      if (hasBox)
        const _Option(
          icon: LucideIcons.circleMinus,
          label: LunchCopy.clearDay,
          action: LunchDayAction.clear,
        ),
    ],
  ),
);

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.action,
  });

  final IconData icon;
  final String label;
  final LunchDayAction action;

  @override
  Widget build(BuildContext context) => NestListRow(
    title: label,
    leading: NestIconTile(
      icon: icon,
      size: NestSize.avatarMedium,
      iconSize: NestSize.iconMedium,
    ),
    onTap: () => Navigator.of(context).pop(action),
  );
}
