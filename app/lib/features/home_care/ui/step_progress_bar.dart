import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// How far through a job's checklist somebody is, as a bar that fills —
/// with the count in words beside it for anybody who cannot see the bar
/// (`FE-13`). It grows to a new value rather than jumping, under the one
/// reduce-motion gate (`FE-15`).
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    required this.progress,
    required this.label,
    this.height = NestSpace.sm,
    super.key,
  });

  /// From 0 to 1.
  final double progress;
  final String label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final motion = NestMotion.of(context);
    final isDone = progress >= 1;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(NestRadius.pill),
              child: SizedBox(
                height: height,
                child: ColoredBox(
                  color: nest.colors.surfaceTint,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: progress.clamp(0, 1)),
                      duration: motion.standard,
                      curve: NestMotion.standardCurve,
                      builder: (context, value, _) => FractionallySizedBox(
                        widthFactor: value,
                        heightFactor: 1,
                        child: ColoredBox(
                          color: isDone
                              ? nest.colors.success
                              : nest.colors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: NestSpace.sm),
          Text(label, style: nest.text.caption),
        ],
      ),
    );
  }
}
