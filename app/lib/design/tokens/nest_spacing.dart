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
  /// A small square mark — a shop's logo beside a list item.
  static const double xs = 8;
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

  /// The kid screens' target: a chore to tick, a letter of a code. A child's
  /// aim is looser than an adult's, and these are the controls they use most
  /// (accounts ADR-0003).
  static const double controlHuge = 72;
  static const double iconSmall = 18;

  /// The glyph inside a `NestBadge`, sized to its caption text.
  static const double iconBadge = 14;
  static const double iconMedium = 22;
  static const double iconLarge = 28;
  static const double iconTile = 52;

  /// A shop's logo: beside a grocery item, and in the shop picker.
  static const double logoSmall = 28;
  static const double logoMedium = 36;

  /// A big icon tile used as a mark — a hero card, a lock, a code screen —
  /// and the glyph inside it.
  static const double mark = 72;
  static const double iconMark = 36;

  /// The nest from the logo, by width (design-system ADR-0003): the welcome and
  /// the launch screen, the household gate and a first-run empty state, and
  /// the home tab's header.
  static const double brandMarkLarge = 184;
  static const double brandMarkMedium = 128;
  static const double brandMarkSmall = 48;

  /// The wordmark, by height, ascenders to descenders: under the welcome's
  /// nest, and under the household gate's. The script's loops and the p's tail
  /// take height the old block letters did not, so these run taller.
  static const double wordmarkLarge = 64;
  static const double wordmarkSmall = 32;

  /// A satellite on the welcome's orbit (`NestDot`).
  static const double dot = 12;
  static const double avatarSmall = 28;
  static const double avatarMedium = 40;
  static const double avatarLarge = 56;
  static const double sheetHandleWidth = 44;
  static const double sheetHandleHeight = 4;
  static const double bottomBarHeight = 68;

  /// The tonal pill behind the selected tab's icon, the way the bar says
  /// where you are without relying on colour alone (`FE-13`).
  static const double barIndicatorWidth = 56;
  static const double barIndicatorHeight = 30;

  /// The widest a place tile on the More screen grows before the grid adds a
  /// column — two on a phone, more on a tablet.
  static const double placeTileMaxWidth = 220;

  /// How much of a document's own image a sheet shows before it would be a
  /// screen of its own. Tall enough to recognise a letter, short enough to
  /// leave the actions under it visible at 200% text.
  static const double previewHeight = 240;

  /// The two sides of a scan shown side by side for checking before saving.
  static const double scanSidesHeight = 180;

  /// A vault document's pages, taller than a preview so print can be read.
  static const double pagesHeight = 420;
}

/// Stroke widths for hairlines and focus rings.
abstract final class NestStroke {
  static const double hairline = 1;
  static const double focus = 2;
}
