import 'package:flutter/widgets.dart';

import '../tokens/nest_colors.dart';
import '../tokens/nest_spacing.dart';

/// A bundled clipart sticker — a chore's picture (todos ADR-0005) — on its own
/// soft Oat tile, the same in both themes as Twig keeps its blush: the art's
/// plum outlines need a light ground, and on the dark canvas they would all
/// but vanish.
///
/// Always decoration: whatever it sits beside already says what it shows.
class NestSticker extends StatelessWidget {
  const NestSticker({
    required this.asset,
    this.size = NestSize.stickerSmall,
    super.key,
  });

  final String asset;

  /// The tile's side; the art is drawn inside it with a margin of its own.
  final double size;

  /// How much of the tile the art fills. The stickers run almost to their
  /// edges, so without this they touch the tile's rounded corners.
  static const artShare = 0.84;

  @override
  Widget build(BuildContext context) {
    final art = size * artShare;
    final radius = size > NestSize.iconTile ? NestRadius.xl : NestRadius.sm;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: NestColors.oat,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Image.asset(
              asset,
              width: art,
              height: art,
              cacheWidth: (art * MediaQuery.devicePixelRatioOf(context)).ceil(),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              // A catalogue entry whose raster has not landed yet is an empty
              // tile, never a red box on a child's screen.
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
