import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../model/avatar_creation.dart';
import 'creation_style_picture.dart';

class CreationStylePicker extends StatelessWidget {
  const CreationStylePicker({
    required this.selected,
    required this.onPick,
    super.key,
  });

  final CreationStyle selected;
  final ValueChanged<CreationStyle> onPick;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const NestSectionHeader(title: AvatarCreationCopy.pickStyle),
      const SizedBox(height: NestSpace.sm),
      NestPickGrid(
        children: [
          for (final style in CreationStyle.values)
            NestPickTile(
              key: ValueKey('style-${style.name}'),
              label: AvatarCreationCopy.style(style),
              semanticLabel: AvatarCreationCopy.styleTitle(style),
              isSelected: style == selected,
              onTap: () => onPick(style),
              picture: CreationStylePicture(style: style),
            ),
        ],
      ),
    ],
  );
}
