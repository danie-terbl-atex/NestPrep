import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';

/// The welcome tour's scrim: the screen dimmed, with a rounded window cut
/// around the spotlighted component and a quiet edge on it, and — once, as
/// the window arrives — a ring that eases outwards from it and fades (welcome-tour ADR-0002,
/// design-system ADR-0002).
class TourScrimPainter extends CustomPainter {
  const TourScrimPainter({
    required this.hole,
    required this.scrim,
    required this.ring,
    required this.pulse,
  });

  /// The window, or null while the next component is being found.
  final Rect? hole;
  final Color scrim;
  final Color ring;

  /// How far through its one pulse the ring is, 0 to 1; 0 draws none.
  final double pulse;

  /// The window's corners at most — less for something small, so a round
  /// button gets a round window and the bar a pill — and how far the ring
  /// travels.
  static const maxRadius = NestRadius.xl + NestSpace.sm;
  static const ringTravel = NestSpace.md;

  /// How strongly the window's edge is drawn, against the ring's colour.
  static const edgeAlpha = 0.7;

  /// The scrim is at least this dark, so the window reads in a light theme.
  static const minScrimAlpha = 0.6;

  static RRect windowOf(Rect hole) => RRect.fromRectAndRadius(
    hole,
    Radius.circular(
      hole.shortestSide / 2 < maxRadius ? hole.shortestSide / 2 : maxRadius,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final window = hole;
    final dimmed = window == null
        ? screen
        : Path.combine(
            PathOperation.difference,
            screen,
            Path()..addRRect(windowOf(window)),
          );
    canvas.drawPath(
      dimmed,
      Paint()
        ..color = scrim.a >= minScrimAlpha
            ? scrim
            : scrim.withValues(alpha: minScrimAlpha),
    );
    if (window == null) return;
    // A quiet edge, so the window reads on a dark page as well as a light one.
    canvas.drawRRect(
      windowOf(window),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = NestStroke.focus
        ..color = ring.withValues(alpha: ring.a * edgeAlpha),
    );
    if (pulse <= 0 || pulse >= 1) return;
    canvas.drawRRect(
      windowOf(window.inflate(ringTravel * pulse)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = NestStroke.focus
        ..color = ring.withValues(alpha: ring.a * (1 - pulse)),
    );
  }

  @override
  bool shouldRepaint(TourScrimPainter old) =>
      old.hole != hole ||
      old.pulse != pulse ||
      old.scrim != scrim ||
      old.ring != ring;
}
