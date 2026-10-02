import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A ring of little stars that flies out from [child] once, each time [burst]
/// changes to a new value — stars landing on a child's screen (todos
/// ADR-0003).
///
/// It is a celebration that **arrives and ends** (design-system ADR-0002):
/// one flight outwards, a fade, and rest. It never loops, it never blocks a
/// tap (the stars ignore the pointer), and it is decoration a screen reader
/// is not told about — whatever it celebrates is said in words beside it.
///
/// Under reduce-motion it does not play at all: the words and the number carry
/// the moment on their own (`FE-15`).
class NestStarBurst extends StatefulWidget {
  const NestStarBurst({
    required this.child,
    required this.burst,
    this.reach = NestSpace.huge,
    super.key,
  });

  final Widget child;

  /// Plays whenever this changes to a value other than zero. Zero is "nothing
  /// to celebrate yet", so the first frame of a screen never bursts.
  final int burst;

  /// How far from the centre the stars fly.
  final double reach;

  static const starCount = 10;

  @override
  State<NestStarBurst> createState() => _NestStarBurstState();
}

class _NestStarBurstState extends State<NestStarBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didUpdateWidget(NestStarBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burst == oldWidget.burst || widget.burst == 0) return;
    final motion = NestMotion.of(context);
    if (motion.isReduced) return;
    // Two "slow" beats: long enough to be seen, short enough to be over
    // before the child's next tap.
    _controller
      ..duration = motion.slow * 2
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NestTheme.of(context).colors;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final t = NestMotion.enter.transform(_controller.value);
                  if (_controller.value == 0 || _controller.value == 1) {
                    return const SizedBox.shrink();
                  }
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < NestStarBurst.starCount; i++)
                        _Star(
                          angle: i * 2 * math.pi / NestStarBurst.starCount,
                          distance: widget.reach * t,
                          // Fades over the second half, so it is seen first.
                          opacity: (2 - 2 * t).clamp(0, 1).toDouble(),
                          color: i.isEven ? colors.warning : colors.accent,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.angle,
    required this.distance,
    required this.opacity,
    required this.color,
  });

  final double angle;
  final double distance;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: Offset(math.cos(angle) * distance, math.sin(angle) * distance),
    child: Opacity(
      opacity: opacity,
      child: Icon(LucideIcons.star, size: NestSize.iconSmall, color: color),
    ),
  );
}
