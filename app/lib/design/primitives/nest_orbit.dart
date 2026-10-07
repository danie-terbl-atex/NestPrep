import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_orbit_rings.dart';

export 'nest_orbit_rings.dart' show NestOrbitLine, NestOrbitRing;

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

/// The mark at the centre of soft rings with the household's things riding
/// them — the picture the app opens on.
///
/// Everything swings into place once (`FE-15`): the mark, then the rings, then
/// each item drifting the last few degrees along its own orbit. With [spins]
/// the rings then keep turning, each by its own [NestOrbitRing.turnRate] per
/// [NestMotion.revolution] (design-system ADR-0006): the welcome's three go
/// different ways at different speeds. Without it the picture comes to rest.
/// Under reduce-motion it is simply there and never moves.
///
/// The picture is laid out at [maxWidth] and scaled down whole when it is
/// given less, so the spacing that keeps neighbouring rings' items apart holds
/// at every width.
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
    this.spins = false,
    super.key,
  });

  final Widget centre;
  final List<NestOrbitItem> items;
  final String semanticsLabel;

  /// The box each orbiting item is drawn in. Geometry is exact rather than
  /// fitted, so nothing can ride off the edge whatever an item contains.
  final double itemExtent;
  final double maxWidth;

  /// Whether the items keep circling once they have arrived.
  final bool spins;

  @override
  State<NestOrbit> createState() => _NestOrbitState();
}

class _NestOrbitState extends State<NestOrbit> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  /// How far the orbit has turned, in revolutions. Stays at zero unless it
  /// spins.
  late final AnimationController _spin = AnimationController(vsync: this);

  /// The mark, then the rings, then one step per item.
  static const _stepsBeforeItems = 2;

  Duration _step = Duration.zero;
  Duration _total = Duration.zero;
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = NestMotion.of(context);
    _syncSpin(motion);
    if (_hasStarted) return;
    _hasStarted = true;
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
  void didUpdateWidget(NestOrbit old) {
    super.didUpdateWidget(old);
    if (old.spins != widget.spins) _syncSpin(NestMotion.of(context));
  }

  /// Starts or stops the turning to match [NestOrbit.spins] and the
  /// reduce-motion gate, which can change while the screen is open. A ring
  /// that stops stays where it got to rather than jumping back.
  void _syncSpin(NestMotion motion) {
    final revolution = motion.revolution;
    if (!widget.spins || revolution == Duration.zero) {
      _spin.stop();
      return;
    }
    if (_spin.isAnimating && _spin.duration == revolution) return;
    _spin
      ..duration = revolution
      ..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
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
        // A picture that keeps moving repaints on its own, not the screen.
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = widget.maxWidth;
              return SizedBox.square(
                dimension: math.min(constraints.maxWidth, width),
                child: FittedBox(
                  child: SizedBox.square(
                    dimension: width,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: NestOrbitRings(
                            progress: _atStep(1),
                            spin: _spin,
                            color: nest.colors.outlineStrong,
                            rings: {for (final item in widget.items) item.ring},
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
                            spin: _spin,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// An item held at its place on the ring, drifting the last of the way round
/// as it fades in, then carried round as its ring turns. The item itself
/// stays upright: the ring turns, the things on it do not tumble.
class _OrbitingItem extends StatelessWidget {
  const _OrbitingItem({
    required this.item,
    required this.width,
    required this.extent,
    required this.progress,
    required this.spin,
  });

  final NestOrbitItem item;
  final double width;
  final double extent;
  final Animation<double> progress;

  /// How far the orbit has turned, in revolutions; the ring multiplies it.
  final Animation<double> spin;

  /// How far back along the ring an item starts, in turns.
  static const _driftTurns = 0.045;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([progress, spin]),
    child: item.child,
    builder: (context, child) {
      final t = progress.value;
      final turns =
          item.turns - _driftTurns * (1 - t) + item.ring.turnRate * spin.value;
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
