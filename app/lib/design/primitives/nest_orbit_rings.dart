import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../tokens/nest_spacing.dart';

/// How a ring's line is drawn. A dashed or dotted ring shows its own turning;
/// a solid one is only seen to turn by what rides it.
enum NestOrbitLine { solid, dashed, dotted }

/// One ring of an orbit: how far out it is, how it is drawn, and how it turns.
@immutable
class NestOrbitRing {
  const NestOrbitRing({
    required this.radiusFraction,
    this.line = NestOrbitLine.solid,
    this.turnRate = 1,
  });

  /// The two rings of the arrival that comes to rest (design-system ADR-0002).
  static const inner = NestOrbitRing(radiusFraction: 0.275);
  static const outer = NestOrbitRing(radiusFraction: 0.408);

  /// The three rings of the turning welcome (design-system ADR-0006), round a
  /// `NestSize.brandMarkLarge` centre, spaced so that the things riding them
  /// — a 12-point dot, a 28-point tile, a 40-point avatar — pass each other
  /// without touching while the rings turn different ways at different rates.
  static const close = NestOrbitRing(
    radiusFraction: 0.235,
    line: NestOrbitLine.dotted,
    turnRate: 3,
  );
  static const middle = NestOrbitRing(
    radiusFraction: 0.32,
    line: NestOrbitLine.dashed,
    turnRate: -2,
  );
  static const far = NestOrbitRing(radiusFraction: 0.441);

  /// Radius as a fraction of the orbit's width. Past `0.5` minus half an item,
  /// something rides off the edge.
  final double radiusFraction;

  final NestOrbitLine line;

  /// Whole turns of this ring per `NestMotion.revolution`; negative turns it
  /// anticlockwise. Whole, so a ring is back where it began each revolution
  /// and the loop has no seam. Two rings with different rates must be at least
  /// half of each one's item apart, or what rides them collides.
  final int turnRate;

  @override
  bool operator ==(Object other) =>
      other is NestOrbitRing &&
      other.radiusFraction == radiusFraction &&
      other.line == line &&
      other.turnRate == turnRate;

  @override
  int get hashCode => Object.hash(radiusFraction, line, turnRate);
}

/// The hairline circles an orbit's items ride, drawn outward from the centre
/// and turned with [spin]. Only a ring something rides is drawn: an empty ring
/// through a large centre mark reads as a line struck through it.
class NestOrbitRings extends StatelessWidget {
  const NestOrbitRings({
    required this.progress,
    required this.spin,
    required this.color,
    required this.rings,
    super.key,
  });

  final Animation<double> progress;

  /// How far the orbit has turned, in revolutions.
  final Animation<double> spin;
  final Color color;
  final Set<NestOrbitRing> rings;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([progress, spin]),
    builder: (context, _) => CustomPaint(
      painter: _OrbitRingsPainter(
        progress: progress.value,
        spin: spin.value,
        color: color,
        rings: rings,
      ),
    ),
  );
}

class _OrbitRingsPainter extends CustomPainter {
  const _OrbitRingsPainter({
    required this.progress,
    required this.spin,
    required this.color,
    required this.rings,
  });

  final double progress;
  final double spin;
  final Color color;
  final Set<NestOrbitRing> rings;

  /// The rings are guides, not structure: they sit under the items rather than
  /// competing with them.
  static const _restingAlpha = 0.7;

  /// Roughly how far apart, along the ring, one dash or dot is from the next.
  static const _dashPitch = NestSpace.lg;
  static const _dotRadius = NestStroke.hairline * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final centre = size.center(Offset.zero);
    final colour = color.withValues(alpha: color.a * progress * _restingAlpha);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = NestStroke.hairline
      ..strokeCap = StrokeCap.round
      ..color = colour;
    final fill = Paint()..color = colour;
    for (final ring in rings) {
      final radius =
          size.width * ring.radiusFraction * (0.85 + 0.15 * progress);
      final turned = ring.turnRate * spin * 2 * math.pi;
      // Counted at rest, so the dashes do not flicker as the ring grows in.
      final count = _marksOn(size.width * ring.radiusFraction);
      switch (ring.line) {
        case NestOrbitLine.solid:
          canvas.drawCircle(centre, radius, stroke);
        case NestOrbitLine.dashed:
          final rect = Rect.fromCircle(center: centre, radius: radius);
          final step = 2 * math.pi / count;
          for (var i = 0; i < count; i++) {
            canvas.drawArc(rect, turned + i * step, step / 2, false, stroke);
          }
        case NestOrbitLine.dotted:
          for (var i = 0; i < count; i++) {
            final angle = turned + i * 2 * math.pi / count;
            canvas.drawCircle(
              centre + Offset(math.cos(angle), math.sin(angle)) * radius,
              _dotRadius,
              fill,
            );
          }
      }
    }
  }

  static int _marksOn(double radius) =>
      math.max(8, (2 * math.pi * radius / _dashPitch).round());

  @override
  bool shouldRepaint(_OrbitRingsPainter old) =>
      old.progress != progress ||
      old.spin != spin ||
      old.color != color ||
      !setEquals(old.rings, rings);
}
