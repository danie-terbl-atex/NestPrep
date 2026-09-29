import 'package:flutter/widgets.dart';

import '../tokens/nest_brand_assets.dart';
import '../tokens/nest_spacing.dart';

/// The nest from the logo: a lunchbox, the calendar at 15, the tick, a house
/// with a heart, and a ball or two, in a woven nest (design-system ADR-0003).
///
/// Drawn as it is, in its own colours, in both themes — it was drawn with
/// dark outlines, so it holds on the night canvas without a plate. Sized by
/// width and laid out at its final height before the image decodes, so nothing
/// under it moves when it lands (`FE-18`).
///
/// Decoration by default. Give it a [semanticsLabel] only where it is the one
/// thing on screen that says whose app this is; beside the wordmark it would be
/// the same name read twice.
class NestBrandMark extends StatelessWidget {
  const NestBrandMark({
    this.width = NestSize.brandMarkMedium,
    this.semanticsLabel,
    super.key,
  });

  final double width;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticsLabel;
    return Image.asset(
      NestBrandAssets.mark,
      width: width,
      height: width / NestBrandAssets.markAspect,
      fit: BoxFit.contain,
      semanticLabel: label,
      excludeFromSemantics: label == null,
    );
  }
}
