import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/avatar_creation.dart';

class CreationStylePicture extends StatelessWidget {
  const CreationStylePicture({required this.style, super.key});

  final CreationStyle style;

  static IconData iconOf(CreationStyle style) => switch (style) {
    CreationStyle.plush => LucideIcons.heart,
    CreationStyle.clay => LucideIcons.shapes,
    CreationStyle.knitted => LucideIcons.spool,
    CreationStyle.wooden => LucideIcons.treeDeciduous,
    CreationStyle.vinyl => LucideIcons.gem,
    CreationStyle.sticker => LucideIcons.sticker,
  };

  static NestTileTint tintOf(CreationStyle style) => switch (style) {
    CreationStyle.plush => NestTileTint.guava,
    CreationStyle.clay => NestTileTint.butter,
    CreationStyle.knitted => NestTileTint.lilac,
    CreationStyle.wooden => NestTileTint.basil,
    CreationStyle.vinyl => NestTileTint.accent,
    CreationStyle.sticker => NestTileTint.guava,
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Center(
      child: NestIconTile(
        icon: iconOf(style),
        tint: tintOf(style),
        size: constraints.maxWidth,
        iconSize: constraints.maxWidth / 2,
      ),
    ),
  );
}
