import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../model/kid_points.dart';

/// A child's stars, big (todos ADR-0003): a gold star, the number, a streak
/// when there is one, and — when stars just landed — a burst and a line that
/// says how many.
///
/// The number counts up to its new value and the stars fly once; under
/// reduce-motion the number is simply there and nothing flies (`FE-15`). The
/// count is said in words as well as drawn (`FE-13`).
class KidStarsCard extends StatelessWidget {
  const KidStarsCard({required this.points, super.key});

  final KidPoints points;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final celebration = points.celebration;
    final streak = points.streak;
    return Semantics(
      container: true,
      label: PointsCopy.kidStarsSaid(points.stars, streak),
      excludeSemantics: true,
      child: NestCard(
        child: Row(
          children: [
            NestStarBurst(
              burst: celebration?.sequence ?? 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.warningSoft,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: NestSize.mark,
                  child: Icon(
                    Icons.star_rounded,
                    size: NestSize.iconMark,
                    color: c.warning,
                  ),
                ),
              ),
            ),
            const SizedBox(width: NestSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CountUp(stars: points.stars),
                  Text(
                    PointsCopy.kidStarsLabel(points.stars),
                    style: nest.text.label.copyWith(color: c.inkSecondary),
                  ),
                  if (celebration != null) ...[
                    const SizedBox(height: NestSpace.xs),
                    Text(
                      PointsCopy.kidJustEarned(celebration.gained),
                      style: nest.text.bodyStrong.copyWith(color: c.success),
                    ),
                  ] else if (points.stars == 0) ...[
                    const SizedBox(height: NestSpace.xs),
                    Text(
                      PointsCopy.kidNoStarsYet,
                      style: nest.text.bodySecondary,
                    ),
                  ],
                  if (streak >= 2) ...[
                    const SizedBox(height: NestSpace.sm),
                    NestTag(
                      label: PointsCopy.kidStreak(streak),
                      tone: NestTagTone.warning,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountUp extends StatelessWidget {
  const _CountUp({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: stars.toDouble()),
      duration: NestMotion.of(context).slow * 2,
      curve: NestMotion.enter,
      builder: (context, value, _) =>
          Text('${value.round()}', style: nest.text.figure),
    );
  }
}
