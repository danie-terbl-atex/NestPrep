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

  /// The smallest a control may be. Not a design choice: `FE-13` sets the
  /// floor at 44×44, and it was 40 until an audit of the semantics tree found
  /// the filter chips, the todo tabs and "Copy last week" all sitting under it.
  /// A thumb is about 45 wide and does not care what the layout wanted.
  static const double controlSmall = 44;
  static const double controlMedium = 48;
  static const double controlLarge = 56;
  static const double iconSmall = 18;
  static const double iconMedium = 22;
  static const double iconLarge = 28;
  static const double iconTile = 52;

  /// The app's own mark and the glyph inside it, on the screens somebody sees
  /// before there is any data — the welcome and the household gate.
  static const double mark = 72;
  static const double iconMark = 36;
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
