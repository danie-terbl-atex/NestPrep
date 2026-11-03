/// Numbers as a home cook reads them — `1 1/2`, `3/4`, `2 1/3` — rather than
/// `1.5`, `0.75`, `2.333` (recipes ADR-0003 §5). Used for spoons, cups and
/// counts on the recipe page, and for how far a recipe is scaled.
///
/// Written with a slash, never as `⅓`: the bundled Mona Sans has no glyph for
/// thirds or eighths, but it does have the OpenType `frac` feature, so the
/// page sets these with `FontFeature.fractions()` and every fraction is drawn
/// alike in the app's own face.
abstract final class KitchenFraction {
  /// The fractions a measuring set or a knife gives you, smallest first.
  static const _parts = [0.0, 1 / 8, 1 / 4, 1 / 3, 1 / 2, 2 / 3, 3 / 4, 1.0];

  static const _fractions = [
    (1 / 8, '1/8'),
    (1 / 4, '1/4'),
    (1 / 3, '1/3'),
    (1 / 2, '1/2'),
    (2 / 3, '2/3'),
    (3 / 4, '3/4'),
  ];

  /// From ten up a fraction is noise; below it, the nearest of [_parts].
  static const _wholeFrom = 10.0;

  /// [value] at the nearest fraction a cook can measure, never zero for a
  /// positive amount — a pinch is still something to add.
  static double round(double value) {
    if (value >= _wholeFrom) return value.roundToDouble();
    final whole = value.floorToDouble();
    final part = _parts.reduce(
      (best, next) =>
          (value - whole - next).abs() < (value - whole - best).abs()
          ? next
          : best,
    );
    final rounded = whole + part;
    return rounded > 0 ? rounded : _parts[1];
  }

  /// Whether [value] is a whole number of [step]s, give or take the
  /// arithmetic's own error.
  static bool isMultipleOf(double value, double step) {
    final steps = value / step;
    return (steps - steps.roundToDouble()).abs() < 0.02;
  }

  /// [value], already rounded by [round], written for the `frac` feature:
  /// `1 1/2`, `3/4`, `3`.
  static String text(double value) {
    final whole = value.floor();
    final part = value - whole;
    final fraction = _fractions
        .where((fraction) => (fraction.$1 - part).abs() < 0.005)
        .firstOrNull
        ?.$2;
    if (fraction == null) return '${value.round()}';
    return whole == 0 ? fraction : '$whole $fraction';
  }
}
