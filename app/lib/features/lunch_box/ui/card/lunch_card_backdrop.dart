import 'package:flutter/material.dart';

import 'lunch_card_palette.dart';

/// The ground a card is drawn on: the look's wash from top to bottom, and
/// two soft round shapes half off the edges — the app's own cream-page
/// warmth, so a card looks like it came from the app it advertises.
/// Decoration only; silent to a screen reader.
class LunchCardBackdrop extends StatelessWidget {
  const LunchCardBackdrop({required this.palette, super.key});

  final LunchCardPalette palette;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _BackdropPainter(palette),
      child: const SizedBox.expand(),
    ),
  );
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.palette);

  final LunchCardPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.ground,
        ).createShader(bounds),
    );
    final (topRight, bottomLeft) = palette.shapes;
    final unit = size.shortestSide;
    canvas
      ..drawCircle(
        Offset(size.width * 0.92, size.height * 0.06),
        unit * 0.42,
        Paint()..color = topRight,
      )
      ..drawCircle(
        Offset(size.width * 0.04, size.height * 0.94),
        unit * 0.36,
        Paint()..color = bottomLeft,
      );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
