import 'package:flutter/material.dart';

import '../../../../design/nest_kit.dart';
import '../../model/lunch_card_style.dart';

/// The colours of one card look, taken from the brand's tokens and nowhere
/// else (`FE-02`, lunch-box ADR-0005): the token set the card is drawn in,
/// the ground washed top to bottom, the two soft shapes behind it, and the
/// surface each day sits on.
@immutable
class LunchCardPalette {
  const LunchCardPalette._({
    required this.theme,
    required this.ground,
    required this.shapes,
    required this.rowSurface,
  });

  factory LunchCardPalette.of(LunchCardStyle style) {
    final theme = style.isDark ? NestTheme.dark() : NestTheme.light();
    final c = theme.colors;
    return switch (style) {
      LunchCardStyle.cream => LunchCardPalette._(
        theme: theme,
        ground: c.canvasWash,
        shapes: (c.tileBasil, c.tileButter),
        rowSurface: c.surfaceGlass,
      ),
      LunchCardStyle.leaf => LunchCardPalette._(
        theme: theme,
        ground: [c.tileBasil, c.successSoft, c.accentSoft],
        shapes: (c.surfaceTint, c.tileLilac),
        rowSurface: c.surfaceGlass,
      ),
      LunchCardStyle.straw => LunchCardPalette._(
        theme: theme,
        ground: [c.warningSoft, c.tileButter, c.canvas],
        shapes: (c.tileGuava, c.surfaceTint),
        rowSurface: c.surfaceGlass,
      ),
      LunchCardStyle.forest => LunchCardPalette._(
        theme: theme,
        ground: c.canvasWash,
        shapes: (c.accentSoft, c.tileLilac),
        rowSurface: c.surface,
      ),
    };
  }

  /// The token set everything on the card reads — the kit's widgets, the
  /// drawn boxes and the wordmark's tint follow it.
  final NestTheme theme;

  /// The ground, washed from top to bottom.
  final List<Color> ground;

  /// The two soft shapes behind the content: top right, bottom left.
  final (Color, Color) shapes;

  /// What each day's row sits on.
  final Color rowSurface;

  /// The swatch the share screen shows for this look.
  Color get swatch => ground.first;
}
