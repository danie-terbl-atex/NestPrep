import 'package:flutter/material.dart';

import '../../shared/copy/app_copy.dart';
import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A loading placeholder that holds the layout a list or card will take
/// (`FE-08`). It pulses unless motion is reduced, in which case it is still.
class NestSkeleton extends StatefulWidget {
  const NestSkeleton({
    this.height = NestSize.controlMedium,
    this.width = double.infinity,
    this.radius = NestRadius.md,
    super.key,
  });

  /// A stack of row-shaped placeholders.
  const factory NestSkeleton.rows({int count, Key? key}) = _NestSkeletonRows;

  final double height;
  final double width;
  final double radius;

  @override
  State<NestSkeleton> createState() => _NestSkeletonState();
}

class _NestSkeletonState extends State<NestSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.5,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (NestMotion.of(context).isReduced) {
      _pulse.stop();
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = NestTheme.of(context).colors.skeleton;
    return Semantics(
      label: AppCopy.loading,
      child: FadeTransition(
        opacity: _pulse,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: SizedBox(height: widget.height, width: widget.width),
        ),
      ),
    );
  }
}

class _NestSkeletonRows extends NestSkeleton {
  const _NestSkeletonRows({this.count = 4, super.key});

  final int count;

  @override
  State<NestSkeleton> createState() => _NestSkeletonRowsState();
}

class _NestSkeletonRowsState extends State<_NestSkeletonRows> {
  @override
  Widget build(BuildContext context) {
    // A placeholder must never be the thing that overflows. It is standing in
    // for content that will scroll, in a frame whose height it cannot know —
    // a short phone, a landscape keyboard, or a screen that grew a row above
    // it — so it scrolls too, and shows as many rows as there is room for
    // (`FE-08`, `FE-14`).
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.count,
      separatorBuilder: (_, _) => const SizedBox(height: NestSpace.md),
      itemBuilder: (_, _) => const NestSkeleton(height: NestSize.controlLarge),
    );
  }
}
