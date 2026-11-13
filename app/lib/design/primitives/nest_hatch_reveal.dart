import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_star_burst.dart';

class NestHatchReveal extends StatefulWidget {
  const NestHatchReveal({
    required this.before,
    required this.after,
    required this.duration,
    this.size = NestSize.avatarHero,
    super.key,
  });

  final Widget before;
  final Widget after;
  final Duration duration;
  final double size;

  static const wobbleEnd = 0.36;
  static const crackEnd = 0.44;
  static const revealEnd = 0.6;

  @override
  State<NestHatchReveal> createState() => _NestHatchRevealState();
}

class _NestHatchRevealState extends State<NestHatchReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addListener(_onTick);
  var _burst = 0;
  var _isReduced = false;
  var _hasStarted = false;

  static const _wobbles = 5;
  static const _maxTurn = 0.16;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    _isReduced = NestMotion.of(context).isReduced;
    if (_isReduced) return;
    _controller
      ..duration = widget.duration
      ..forward();
  }

  void _onTick() {
    if (_burst == 0 && _controller.value >= NestHatchReveal.crackEnd) {
      setState(() => _burst = 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = NestTheme.of(context).colors.highlight;
    final after = SizedBox.square(dimension: widget.size, child: widget.after);
    if (_isReduced) return after;
    return SizedBox.square(
      dimension: widget.size,
      child: NestStarBurst(
        burst: _burst,
        reach: widget.size * 0.7,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final wobble = (t / NestHatchReveal.wobbleEnd).clamp(0.0, 1.0);
            final crack =
                ((t - NestHatchReveal.wobbleEnd) /
                        (NestHatchReveal.crackEnd - NestHatchReveal.wobbleEnd))
                    .clamp(0.0, 1.0);
            final reveal =
                ((t - NestHatchReveal.crackEnd) /
                        (NestHatchReveal.revealEnd - NestHatchReveal.crackEnd))
                    .clamp(0.0, 1.0);
            final turn =
                math.sin(wobble * math.pi * 2 * _wobbles) *
                _maxTurn *
                wobble *
                (1 - crack);
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (crack > 0)
                  Opacity(
                    opacity: (1 - reveal) * crack,
                    child: Transform.scale(
                      scale: 0.6 + crack * 0.8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: glow,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(dimension: widget.size),
                      ),
                    ),
                  ),
                if (reveal < 1)
                  Opacity(
                    opacity: 1 - crack,
                    child: Transform.rotate(
                      angle: turn,
                      alignment: Alignment.bottomCenter,
                      child: Transform.scale(
                        scale: 1 + crack * 0.12,
                        child: SizedBox.square(
                          dimension: widget.size,
                          child: widget.before,
                        ),
                      ),
                    ),
                  ),
                if (reveal > 0)
                  Opacity(
                    opacity: reveal,
                    child: Transform.scale(
                      scale: 0.5 + NestMotion.celebrate.transform(reveal) * 0.5,
                      child: after,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
