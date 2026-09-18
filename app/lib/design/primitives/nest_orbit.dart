import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// Which of the two rings a thing sits on.
enum NestOrbitRing {
  inner(0.275),
  outer(0.408);

  const NestOrbitRing(this.radiusFraction);

  /// Radius as a fraction of the orbit's width. The outer one is as far out as
  /// it goes: past `0.5` minus half an item, something rides off the edge.
  final double radiusFraction;
}

/// One thing in orbit: what to draw, which ring it rides, and where on it.
@immutable
class NestOrbitItem {
  const NestOrbitItem({
    required this.child,
    required this.ring,
    required this.turns,
  });

  final Widget child;
  final NestOrbitRing ring;

  /// Position on the ring, clockwise from the top, in turns (`0.25` is east).
  final double turns;
}

/// The mark at the centre of two soft rings with the household's things riding
/// them — the picture the app opens on.
///
/// Everything swings into place once and stops (`FE-15`): the mark, then the
/// rings, then each item drifting the last few degrees along its own orbit.
/// It is an arrival, not a carousel — a screen that never settles is a test
/// that never passes and a phone that never idles.
///
/// The whole picture is **one node to a screen reader**, labelled
/// [semanticsLabel]; the items carry no semantics of their own, because a list
/// of decorative glyphs read one by one tells nobody anything (`FE-13`). For
/// the same reason the items do not scale with the platform's text setting:
/// they are an illustration, their meaning is in the label, and a 200% initial
/// in a 40-pixel mark is a clipped smudge rather than an accommodation.
class NestOrbit extends StatefulWidget {
  const NestOrbit({
    required this.centre,
    required this.items,
    required this.semanticsLabel,
    this.itemExtent = NestSize.iconTile,
    this.maxWidth = 340,
    super.key,
  });

  final Widget centre;
  final List<NestOrbitItem> items;
  final String semanticsLabel;

  /// The box each orbiting item is drawn in. Geometry is exact rather than
  /// fitted, so nothing can ride off the edge whatever an item contains.
  final double itemExtent;
  final double maxWidth;

  @override
  State<NestOrbit> createState() => _NestOrbitState();
}

class _NestOrbitState extends State<NestOrbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  /// The mark, then the rings, then one step per item.
  static const _stepsBeforeItems = 2;

  Duration _step = Duration.zero;
  Duration _total = Duration.zero;
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    final motion = NestMotion.of(context);
    _step = motion.stagger;
    final steps = widget.items.length + _stepsBeforeItems;
    _total = _step * (steps - 1) + motion.standard;
    if (_total == Duration.zero) {
      _controller.value = 1;
      return;
    }
    _controller
      ..duration = _total
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The slice of the whole entrance that step [index] occupies.
  Animation<double> _atStep(int index) {
    if (_total == Duration.zero) return kAlwaysCompleteAnimation;
    final begin = _step * index;
    final end = begin + NestMotion.of(context).standard;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(
        begin.inMicroseconds / _total.inMicroseconds,
        math.min(1, end.inMicroseconds / _total.inMicroseconds),
        curve: NestMotion.enter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      label: widget.semanticsLabel,
      image: true,
      excludeSemantics: true,
      child: MediaQuery.withNoTextScaling(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, widget.maxWidth);
            return SizedBox.square(
              dimension: width,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _OrbitRings(
                      progress: _atStep(1),
                      color: nest.colors.outlineStrong,
                    ),
                  ),
                  Center(
                    child: _Arriving(
                      progress: _atStep(0),
                      child: widget.centre,
                    ),
                  ),
                  for (final (index, item) in widget.items.indexed)
                    _OrbitingItem(
                      item: item,
                      width: width,
                      extent: widget.itemExtent,
                      progress: _atStep(index + _stepsBeforeItems),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// An item held at its place on the ring, drifting the last of the way round
/// as it fades in.
class _OrbitingItem extends StatelessWidget {
  const _OrbitingItem({
    required this.item,
    required this.width,
    required this.extent,
    required this.progress,
  });

  final NestOrbitItem item;
  final double width;
  final double extent;
  final Animation<double> progress;

  /// How far back along the ring an item starts, in turns.
  static const _driftTurns = 0.045;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    child: item.child,
    builder: (context, child) {
      final t = progress.value;
      final turns = item.turns - _driftTurns * (1 - t);
      final radius = width * item.ring.radiusFraction;
      final angle = turns * 2 * math.pi - math.pi / 2;
      return Positioned(
        left: width / 2 + radius * math.cos(angle) - extent / 2,
        top: width / 2 + radius * math.sin(angle) - extent / 2,
        width: extent,
        height: extent,
        child: Center(
          child: Transform.scale(
            scale: 0.6 + 0.4 * t,
            child: Opacity(opacity: t, child: child),
          ),
        ),
      );
    },
  );
}

/// Fades and scales one thing into place — the mark at the centre.
class _Arriving extends StatelessWidget {
  const _Arriving({required this.progress, required this.child});

  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    child: child,
    builder: (context, child) => Transform.scale(
      scale: 0.7 + 0.3 * progress.value,
      child: Opacity(opacity: progress.value, child: child),
    ),
  );
}

/// The two hairline circles the items ride, drawn outward from the centre.
class _OrbitRings extends StatelessWidget {
  const _OrbitRings({required this.progress, required this.color});

  final Animation<double> progress;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (context, _) => CustomPaint(
      painter: _OrbitRingsPainter(progress: progress.value, color: color),
    ),
  );
}

class _OrbitRingsPainter extends CustomPainter {
  const _OrbitRingsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final centre = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = NestStroke.hairline
      ..color = color.withValues(alpha: color.a * progress * _restingAlpha);
    for (final ring in NestOrbitRing.values) {
      canvas.drawCircle(
        centre,
        size.width * ring.radiusFraction * (0.85 + 0.15 * progress),
        paint,
      );
    }
  }

  /// The rings are guides, not structure: they sit under the items rather than
  /// competing with them.
  static const _restingAlpha = 0.7;

  @override
  bool shouldRepaint(_OrbitRingsPainter old) =>
      old.progress != progress || old.color != color;
}
