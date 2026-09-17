/// The spacing scale. Every padding, gap and inset is one of these.
abstract final class NestSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// The horizontal gutter of every screen at phone width.
  static const double gutter = 20;
}

/// Corner radii. The look is round: cards and tiles sit at `lg`/`xl`, and
/// anything that reads as a control is a full pill.
abstract final class NestRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 999;
}

/// Fixed dimensions: control heights, icon sizes and the touch-target floor.
abstract final class NestSize {
  static const double touchTarget = 48;
  static const double controlSmall = 40;
  static const double controlMedium = 48;
  static const double controlLarge = 56;
  static const double iconSmall = 18;
  static const double iconMedium = 22;
  static const double iconLarge = 28;
  static const double iconTile = 52;
  static const double avatarSmall = 28;
  static const double avatarMedium = 40;
  static const double avatarLarge = 56;
  static const double sheetHandleWidth = 44;
  static const double sheetHandleHeight = 4;
  static const double bottomBarHeight = 68;
}

/// Stroke widths for hairlines and focus rings.
abstract final class NestStroke {
  static const double hairline = 1;
  static const double focus = 2;
}
