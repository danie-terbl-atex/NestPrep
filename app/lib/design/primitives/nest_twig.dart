import 'package:flutter/widgets.dart';

import '../tokens/nest_colors.dart';
import '../tokens/nest_imagery.dart';
import '../tokens/nest_spacing.dart';

/// Twig, NestPrep's AI mascot (design-system ADR-0012), in one of its
/// [NestTwigPose]s. Twig means *AI did this*: a screen shows it only where the
/// model is doing or did the work, and never on a path where the phone stood
/// in for it.
///
/// Twig always sits on its own soft blush tile, the same in both themes, as
/// the arch sits on Guava: the art's dark brown outline needs a light ground,
/// and on the dark canvas it would all but vanish. The picture holds its box
/// before it is decoded, so nothing around it moves when it arrives.
///
/// Decoration unless given a [semanticsLabel] — label it only where nothing
/// beside it already says the AI is at work.
class NestTwig extends StatelessWidget {
  const NestTwig({
    required this.pose,
    this.size = NestSize.twigMedium,
    this.semanticsLabel,
    super.key,
  });

  final NestTwigPose pose;

  /// The tile's side; Twig is drawn inside it with a margin of its own.
  final double size;
  final String? semanticsLabel;

  /// How much of the tile the art fills. The art carries little margin of its
  /// own, so without this the crest and the feet touch the tile's edge.
  static const artShare = 0.94;

  @override
  Widget build(BuildContext context) {
    final radius = size > NestSize.iconTile ? NestRadius.xl : NestRadius.md;
    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: NestColors.blush,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Image.asset(
            pose.asset,
            width: size * artShare,
            height: size * artShare,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
    final label = semanticsLabel;
    if (label == null) return ExcludeSemantics(child: tile);
    return Semantics(label: label, image: true, child: tile);
  }
}
