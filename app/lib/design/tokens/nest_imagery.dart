import 'package:flutter/widgets.dart';

/// Brand mood photography (design-system ADR-0010). Concept art only: never
/// shown as a particular lunch.
abstract final class NestImagery {
  static const welcomeLunch = 'assets/brand/welcome_lunch.jpg';

  static const premiumRecipes = 'assets/premium/recipes.jpg';
  static const premiumShops = 'assets/premium/shops.jpg';
  static const premiumWhereWeAre = 'assets/premium/where_we_are.jpg';
  static const premiumNannyHub = 'assets/premium/nanny_hub.jpg';
  static const premiumHomeCare = 'assets/premium/home_care.jpg';
  static const premiumTwoHomes = 'assets/premium/two_homes.jpg';
  static const premiumDocuments = 'assets/premium/documents.jpg';
}

/// Twig, NestPrep's mascot, in each of the five poses Daniel supplied
/// (design-system ADR-0026). Drawn only through `NestTwig`; the rasters are
/// the vault's originals scaled by `sips -Z 384`, never edited by hand.
enum NestTwigPose {
  /// Waving, with a green lunchbox.
  waving('assets/brand/twig/twig.png'),

  /// Welcoming, one wing raised: the pose that is cut into a rig, so it can
  /// really wave.
  welcome('assets/brand/twig/twig_welcome.png', rig: NestTwigRig.welcome),

  /// Planning, with a ticked calendar.
  planning('assets/brand/twig/twig_planning.png'),

  /// Thinking.
  thinking('assets/brand/twig/twig_thinking.png'),

  /// Celebrating.
  celebrate('assets/brand/twig/twig_celebrate.png');

  const NestTwigPose(this.asset, {this.rig = const []});

  final String asset;

  /// The pose cut into layers, in draw order, or empty for a pose that only
  /// moves whole.
  final List<NestTwigLayer> rig;

  /// The side of every raster: the largest Twig (`NestSize.twigLarge`) on a
  /// 4× screen, and no more (`FE-18`).
  static const rasterSize = 384;
}

/// What a layer of a rigged pose is, which says how an action moves it.
enum NestTwigPart { body, wing, crest, tail, eyesClosed }

/// One cut-out layer of a rigged pose: a square raster the size of the pose,
/// so the layers stacked untouched are the pose, turning about [pivot] (a
/// fraction of the square, from its top left). Made by `tools/twig-rig/` from
/// the 1254 px master, never edited by hand.
@immutable
class NestTwigLayer {
  const NestTwigLayer(this.part, this.asset, this.pivot);

  final NestTwigPart part;
  final String asset;
  final Offset pivot;
}

/// The rigs, in draw order.
abstract final class NestTwigRig {
  static const rasterSize = 512;

  /// The welcome pose: tail and wing behind the body, whose outline hides
  /// their joints; the crest on top, carrying a patch of the head over its
  /// base; the closed eyes last, shown only for a blink. Pivots from
  /// `tools/twig-rig/rig.json`, in pixels of the 512 canvas.
  static const welcome = [
    NestTwigLayer(
      NestTwigPart.tail,
      'assets/brand/twig/rig/tail.webp',
      Offset(351.9 / rasterSize, 404.2 / rasterSize),
    ),
    NestTwigLayer(
      NestTwigPart.wing,
      'assets/brand/twig/rig/wing.webp',
      Offset(196.8 / rasterSize, 318.5 / rasterSize),
    ),
    NestTwigLayer(
      NestTwigPart.body,
      'assets/brand/twig/rig/body.webp',
      Offset.zero,
    ),
    NestTwigLayer(
      NestTwigPart.crest,
      'assets/brand/twig/rig/crest.webp',
      Offset(283.8 / rasterSize, 108.6 / rasterSize),
    ),
    NestTwigLayer(
      NestTwigPart.eyesClosed,
      'assets/brand/twig/rig/eyes_closed.webp',
      Offset.zero,
    ),
  ];
}
