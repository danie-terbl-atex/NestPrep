import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/nest_kit.dart';

/// A row that opens another screen: an icon tile, a title, an optional line
/// under it, and a chevron. The account centre and About both list their
/// pages with it (`ENG-02`). It navigates by route, so every page it opens is
/// deep-linkable (`FE-17`).
class LinkRow extends StatelessWidget {
  const LinkRow({
    required this.icon,
    required this.title,
    required this.path,
    this.subtitle,
    this.tint = NestTileTint.accent,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String path;
  final NestTileTint tint;

  @override
  Widget build(BuildContext context) => NestListRow(
    leading: NestIconTile(
      icon: icon,
      tint: tint,
      size: NestSize.avatarMedium,
      iconSize: NestSize.iconMedium,
    ),
    title: title,
    subtitle: subtitle,
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.push(path),
  );
}
