import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import 'tour_placed_callout.dart';
import 'tour_scrim_painter.dart';

/// The tour's whole surface over the app (welcome-tour ADR-0002): the scrim
/// with its window, the window travelling from one component to the next,
/// one pulse as it arrives, and the callout beside it once it has.
///
/// It takes every tap: the app underneath is not usable while the tour runs.
/// A tap inside the window is [onTapWindow]; anywhere else does nothing.
class TourSpotlight extends StatefulWidget {
  const TourSpotlight({
    required this.hole,
    required this.callout,
    required this.onTapWindow,
    this.keepClear,
    super.key,
  });

  /// Something the callout must not sit over — the floating bar.
  final Rect? keepClear;

  /// Where the window goes, in this widget's coordinates; null while the
  /// next component is being found.
  final Rect? hole;

  /// The callout for [hole]; shown once the window has arrived.
  final Widget? callout;
  final VoidCallback onTapWindow;

  @override
  State<TourSpotlight> createState() => _TourSpotlightState();
}

class _TourSpotlightState extends State<TourSpotlight>
    with TickerProviderStateMixin {
  late final AnimationController _move = AnimationController(vsync: this);
  late final AnimationController _pulse = AnimationController(vsync: this);
  Rect? _from;
  Rect? _to;

  @override
  void initState() {
    super.initState();
    _to = widget.hole;
    _from = widget.hole;
    _move
      ..value = 1
      ..addStatusListener(_onMoved);
  }

  @override
  void didUpdateWidget(TourSpotlight old) {
    super.didUpdateWidget(old);
    final hole = widget.hole;
    if (hole == old.hole || hole == null) return;
    final motion = NestMotion.of(context);
    if (old.hole == null) {
      // Arriving at a new component: from wherever the window last was.
      _from = _shown ?? hole;
      _to = hole;
      _pulse.value = 0;
      _move
        ..duration = motion.standard
        ..forward(from: 0);
      return;
    }
    // The same component moved — a list settling, the screen turning.
    _to = hole;
    if (!_move.isAnimating) _from = hole;
  }

  void _onMoved(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _from = _to;
    final motion = NestMotion.of(context);
    if (motion.isReduced) return;
    _pulse
      ..duration = motion.slow * 2
      ..forward(from: 0);
  }

  Rect? get _shown {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return to;
    return Rect.lerp(from, to, NestMotion.enter.transform(_move.value));
  }

  @override
  void dispose() {
    _move.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NestTheme.of(context).colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final hole = widget.hole;
        if (hole != null && hole.contains(details.localPosition)) {
          widget.onTapWindow();
        }
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_move, _pulse]),
        builder: (context, child) => CustomPaint(
          painter: TourScrimPainter(
            hole: widget.hole == null ? null : _shown,
            scrim: colors.scrim,
            ring: colors.accent,
            pulse: _pulse.value,
          ),
          child: child,
        ),
        child: TourPlacedCallout(
          hole: widget.hole,
          arrival: _move,
          callout: widget.callout,
          keepClear: widget.keepClear,
        ),
      ),
    );
  }
}
