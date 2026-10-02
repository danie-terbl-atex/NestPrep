/// The two pieces of the logo the app draws, written by
/// `tools/brand/extract_brand_assets.py`: the nest cut from Daniel's original
/// (design-system ADR-0003), the words set in the script face (ADR-0007). Never
/// redrawn, recoloured or rearranged by a screen: a screen asks the kit for
/// `NestBrandMark`, `NestWordmark` or `NestBrandLockup`.
abstract final class NestBrandAssets {
  /// The nest without the words, on transparent.
  static const mark = 'assets/brand/nest_mark.png';

  /// Width over height of [mark], so it is laid out at its final size before
  /// the image has decoded and nothing below it jumps (`FE-18`).
  static const markAspect = 720 / 553;

  /// The words "Nest Prep" in Grand Hotel as an alpha mask, tinted by the
  /// theme.
  static const wordmark = 'assets/brand/nest_wordmark.png';

  /// Width over height of [wordmark].
  static const wordmarkAspect = 720 / 248;
}
