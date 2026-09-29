import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// One choice before planning: a tile, what it is, what it does now, and the
/// switch. The whole row toggles, so the target is the row, not the switch
/// alone (`FE-13`).
class PlanWeekToggleRow extends StatelessWidget {
  const PlanWeekToggleRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final NestTileTint tint;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: NestListRow(
      title: title,
      subtitle: subtitle,
      leading: NestIconTile(
        icon: icon,
        tint: tint,
        size: NestSize.avatarMedium,
      ),
      trailing: Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    ),
  );
}
