import 'package:flutter/widgets.dart';

import '../tokens/nest_brand_assets.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// The words "Nest Prep" as the logo draws them — set once in the script face
/// by the brand tool and drawn from that image, never retyped in a [Text]
/// (design-system ADR-0003, ADR-0007).
///
/// The asset is an alpha mask; the colour is the theme's `accent`, which in
/// light is the wordmark's own forest green and in dark the lifted leaf that
/// holds on the night canvas. A screen reader hears [semanticsLabel] once, as
/// the heading it is.
class NestWordmark extends StatelessWidget {
  const NestWordmark({
    required this.semanticsLabel,
    this.height = NestSize.wordmarkLarge,
    super.key,
  });

  final String semanticsLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      label: semanticsLabel,
      header: true,
      excludeSemantics: true,
      child: Image.asset(
        NestBrandAssets.wordmark,
        height: height,
        width: height * NestBrandAssets.wordmarkAspect,
        fit: BoxFit.contain,
        color: nest.colors.accent,
        colorBlendMode: BlendMode.srcIn,
      ),
    );
  }
}
