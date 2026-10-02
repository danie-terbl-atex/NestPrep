import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// A time of day to choose, as one row: what it is for, and the time.
class SettingTimeRow extends StatelessWidget {
  const SettingTimeRow({
    required this.title,
    required this.time,
    required this.onTap,
    super.key,
  });

  final String title;
  final String time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return MergeSemantics(
      child: NestListRow(
        leading: const NestIconTile(
          icon: Icons.schedule_rounded,
          tint: NestTileTint.lilac,
          size: NestSize.avatarMedium,
          iconSize: NestSize.iconMedium,
        ),
        title: title,
        trailing: Text(time, style: nest.text.title),
        onTap: onTap,
      ),
    );
  }
}
