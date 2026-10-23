/// Brand mood photography (design-system ADR-0010). Concept art only: never
/// shown as a particular lunch.
abstract final class NestImagery {
  static const welcomeLunch = 'assets/brand/welcome_lunch.jpg';
}

/// Twig, NestPrep's AI mascot, in each of the five poses Daniel supplied
/// (design-system ADR-0012). Drawn only through `NestTwig`; the rasters are
/// the vault's originals scaled by `sips -Z 384`, never edited by hand.
enum NestTwigPose {
  /// Waving, with a green lunchbox — an invitation to let the AI help.
  waving('assets/brand/twig/twig.png'),

  /// Welcoming — the way into a flow the AI does.
  welcome('assets/brand/twig/twig_welcome.png'),

  /// Planning, with a ticked calendar — the AI building the week.
  planning('assets/brand/twig/twig_planning.png'),

  /// Thinking — the AI reading or drafting.
  thinking('assets/brand/twig/twig_thinking.png'),

  /// Celebrating — what the AI did is in.
  celebrate('assets/brand/twig/twig_celebrate.png');

  const NestTwigPose(this.asset);

  final String asset;

  /// The side of every raster: the largest Twig (`NestSize.twigLarge`) on a
  /// 4× screen, and no more (`FE-18`).
  static const rasterSize = 384;
}
