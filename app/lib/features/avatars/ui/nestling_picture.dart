import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/avatar_catalogue.g.dart';

class NestlingPicture extends StatelessWidget {
  const NestlingPicture({
    required this.name,
    required this.label,
    required this.stage,
    required this.color,
    this.size,
    super.key,
  });

  final String name;
  final String label;
  final int stage;
  final MemberColor color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final picture = AssetImage(avatarAssetPath(nestlingAssetId(name, stage)));
    final fixed = size;
    if (fixed != null) {
      return NestAvatar(
        name: label,
        color: color,
        size: fixed,
        picture: picture,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => NestAvatar(
        name: label,
        color: color,
        size: constraints.maxWidth,
        picture: picture,
      ),
    );
  }
}
