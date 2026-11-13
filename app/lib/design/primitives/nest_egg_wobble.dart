import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';

class NestEggWobble extends StatefulWidget {
  const NestEggWobble({
    required this.child,
    this.size = NestSize.avatarHero,
    super.key,
  });

  final Widget child;
  final double size;

  static const rockShare = 0.45;
  static const maxTurn = 0.14;
  static const rocks = 3;

  @override
  State<NestEggWobble> createState() => _NestEggWobbleState();
}

class _NestEggWobbleState extends State<NestEggWobble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cycle = NestMotion.of(context).wobble;
    if (cycle == Duration.zero) {
      _controller.stop();
      return;
    }
    if (_controller.duration == cycle && _controller.isAnimating) return;
    _controller
      ..duration = cycle
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = SizedBox.square(dimension: widget.size, child: widget.child);
    if (!_controller.isAnimating) return child;
    return AnimatedBuilder(
      animation: _controller,
      child: child,
      builder: (context, child) {
        final t = _controller.value / NestEggWobble.rockShare;
        final turn = t >= 1
            ? 0.0
            : math.sin(t * math.pi * 2 * NestEggWobble.rocks) *
                  NestEggWobble.maxTurn *
                  math.sin(t * math.pi);
        return Transform.rotate(
          angle: turn,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
    );
  }
}
