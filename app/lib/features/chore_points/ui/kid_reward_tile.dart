import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../model/kid_points.dart';
import '../model/reward.dart';
import 'reward_icon_glyph.dart';

/// One treat on a child's shelf (todos ADR-0003): its picture, its name, what
/// it costs, how close they are — and, once it is within reach, the button
/// that asks for it.
///
/// Out of reach it says how many more stars it needs, in words and as a bar
/// (`FE-13`); asked for, it says so rather than offering the button again.
class KidRewardTile extends StatelessWidget {
  const KidRewardTile({
    required this.reward,
    required this.points,
    required this.isAsking,
    required this.onAsk,
    super.key,
  });

  final Reward reward;
  final KidPoints points;
  final bool isAsking;

  /// Null when this child may only look (`view` on to-dos).
  final VoidCallback? onAsk;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final canAfford = points.canAfford(reward);
    final asked = points.isAskedFor(reward);
    return NestCard(
      variant: canAfford ? NestCardVariant.raised : NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestIconTile(icon: reward.icon.glyph, tint: reward.icon.tint),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.title, style: nest.text.title),
                    Text(
                      PointsCopy.starsCount(reward.cost),
                      style: nest.text.label.copyWith(color: c.warning),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          _Progress(fraction: points.progressTowards(reward)),
          const SizedBox(height: NestSpace.md),
          if (asked)
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestTag(
                label: PointsCopy.kidAsked,
                tone: NestTagTone.accent,
                icon: Icons.hourglass_top_rounded,
              ),
            )
          else if (canAfford && onAsk != null)
            NestButton(
              label: PointsCopy.kidGetIt,
              icon: Icons.redeem_rounded,
              isLoading: isAsking,
              onPressed: isAsking ? null : onAsk,
            )
          else
            Text(
              canAfford
                  ? PointsCopy.kidEnoughStars
                  : PointsCopy.kidMoreToGo(points.starsToGo(reward)),
              style: nest.text.bodySecondary,
            ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NestRadius.pill),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: NestMotion.of(context).slow,
          curve: NestMotion.enter,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: NestSpace.sm,
            backgroundColor: nest.colors.surfaceTint,
            color: nest.colors.warning,
          ),
        ),
      ),
    );
  }
}
