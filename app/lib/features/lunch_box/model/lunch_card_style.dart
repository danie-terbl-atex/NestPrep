/// The four looks a lunch card comes in, all drawn from the brand's tokens
/// (lunch-box ADR-0005). The look is the style's alone — never the phone's
/// theme — so the same week exports the same image every time.
enum LunchCardStyle {
  /// The app's own cream page.
  cream(isDark: false),

  /// The logo's lunchbox green, as a soft tint.
  leaf(isDark: false),

  /// The nest's woven straw.
  straw(isDark: false),

  /// The brand at night: the dark palette, the wordmark in lifted leaf.
  forest(isDark: true);

  const LunchCardStyle({required this.isDark});

  /// Drawn with the dark token set rather than the light one.
  final bool isDark;
}
