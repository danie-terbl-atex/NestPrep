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
    this.iconSize = NestSize.iconLarge,
    this.label,
    super.key,
  });

  final IconData icon;
  final NestTileTint tint;
  final double size;

  /// The glyph inside the tile. It does not follow [size]: a tile used as a
  /// mark rather than a row's leading wants a different ratio, and guessing
  /// one from the box is how a 28-pixel icon ends up in a 96-pixel square.
  final double iconSize;
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
    // A big tile reads as a blob at the row radius; it wants the next one up.
    final radius = size > NestSize.iconTile ? NestRadius.xl : NestRadius.md;
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Icon(icon, color: c.accentInk, size: iconSize),
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
