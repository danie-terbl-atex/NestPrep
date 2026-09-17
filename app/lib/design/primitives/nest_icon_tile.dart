import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

enum NestTileTint { accent, pink, mint, sky, peach }

/// The rounded pastel square with an icon in it, used as a category marker
/// and as a row's leading. Tint is decorative; the label or row text is the
/// signal (`FE-13`).
class NestIconTile extends StatelessWidget {
  const NestIconTile({
    required this.icon,
    this.tint = NestTileTint.accent,
    this.size = NestSize.iconTile,
    this.label,
    super.key,
  });

  final IconData icon;
  final NestTileTint tint;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final fill = switch (tint) {
      NestTileTint.accent => c.accentSoft,
      NestTileTint.pink => c.tilePink,
      NestTileTint.mint => c.tileMint,
      NestTileTint.sky => c.tileSky,
      NestTileTint.peach => c.tilePeach,
    };
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(NestRadius.md),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, color: c.accentInk, size: NestSize.iconLarge),
      ),
    );
    final text = label;
    if (text == null) return tile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        const SizedBox(height: NestSpace.sm),
        Text(text, style: nest.text.label, textAlign: TextAlign.center),
      ],
    );
  }
}
