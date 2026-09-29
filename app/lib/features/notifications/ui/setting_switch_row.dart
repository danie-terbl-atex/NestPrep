import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// A choice that is on or off, as one row: its tile, what it is, what it
/// means, and the switch. Merged for a screen reader into one node that reads
/// the words and says whether it is on (`FE-13`); tapping anywhere on the row
/// flips it.
class SettingSwitchRow extends StatelessWidget {
  const SettingSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.tint = NestTileTint.accent,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final NestTileTint tint;

  /// Null while a change is on its way, so it cannot be pressed twice.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    return MergeSemantics(
      child: NestListRow(
        leading: NestIconTile(
          icon: icon,
          tint: tint,
          size: NestSize.avatarMedium,
          iconSize: NestSize.iconMedium,
        ),
        title: title,
        subtitle: subtitle,
        trailing: Switch(value: value, onChanged: change),
        onTap: change == null ? null : () => change(!value),
      ),
    );
  }
}
