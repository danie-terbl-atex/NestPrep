import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_card.dart';
import 'nest_icon_tile.dart';

/// One place a person can go, as a card in a grid: a tinted icon, its name in
/// the serif and one line on what is there. The More screen is built from
/// these. The name is the signal; the icon and its tint only help the eye
/// (`FE-13`).
///
/// It owns nothing outside its own box and never navigates — the caller says
/// what a tap does (`FE-03`).
class NestPlaceTile extends StatelessWidget {
  const NestPlaceTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tint = NestTileTint.accent,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final NestTileTint tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final subtitleText = subtitle;
    return Semantics(
      button: true,
      container: true,
      child: NestCard(
        padding: const EdgeInsets.all(NestSpace.lg),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            NestIconTile(
              icon: icon,
              tint: tint,
              size: NestSize.avatarMedium + NestSpace.xs,
              iconSize: NestSize.iconMedium,
            ),
            const SizedBox(height: NestSpace.md),
            Text(title, style: nest.text.title),
            if (subtitleText != null) ...[
              const SizedBox(height: NestSpace.xxs),
              Text(
                subtitleText,
                style: nest.text.caption.copyWith(
                  color: nest.colors.inkSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
