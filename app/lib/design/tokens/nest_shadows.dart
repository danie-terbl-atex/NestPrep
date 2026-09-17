import 'package:flutter/material.dart';

/// Elevation is a soft, wide glow rather than a hard drop; in the dark theme
/// surfaces separate by tone and shadows nearly vanish.
@immutable
class NestShadows {
  const NestShadows({required this.card, required this.floating});

  /// Under a card resting on the canvas.
  final List<BoxShadow> card;

  /// Under a floating bar, sheet or the primary button.
  final List<BoxShadow> floating;

  static const light = NestShadows(
    card: [
      BoxShadow(color: Color(0x14201A3A), blurRadius: 24, offset: Offset(0, 8)),
    ],
    floating: [
      BoxShadow(
        color: Color(0x1F201A3A),
        blurRadius: 32,
        offset: Offset(0, 12),
      ),
    ],
  );

  static const dark = NestShadows(
    card: [
      BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 6)),
    ],
    floating: [
      BoxShadow(
        color: Color(0x59000000),
        blurRadius: 28,
        offset: Offset(0, 10),
      ),
    ],
  );
}
