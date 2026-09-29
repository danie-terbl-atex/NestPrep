import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../../kid_accounts/ui/kid_moment_card.dart';
import '../model/kid_points.dart';
import '../model/reward.dart';
import 'kid_reward_tile.dart';
import 'request_status_tag.dart';

/// The treats a child is saving for, and what they have asked for (todos
/// ADR-0003). An empty shelf says who fills it rather than disappearing — the
/// section is still where the treats will be (`FE-08`).
class KidRewardShelf extends StatelessWidget {
  const KidRewardShelf({
    required this.points,
    required this.isAsking,
    required this.onAsk,
    super.key,
  });

  final KidPoints points;
  final bool Function(Reward reward) isAsking;
  final void Function(Reward reward) onAsk;

  /// How many of their own requests the shelf lists.
  static const recentRequests = 5;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final requests = points.requests.take(recentRequests).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: PointsCopy.kidShelfTitle),
        const SizedBox(height: NestSpace.sm),
        if (points.rewards.isEmpty)
          const KidMomentCard(
            icon: Icons.card_giftcard_rounded,
            tint: NestTileTint.pink,
            title: PointsCopy.kidShelfEmpty,
            message: PointsCopy.kidShelfEmptyBody,
          ),
        for (final (index, reward) in points.rewards.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestRiseIn(
              index: index,
              child: KidRewardTile(
                key: ValueKey(reward.id),
                reward: reward,
                points: points,
                isAsking: isAsking(reward),
                onAsk: points.canSpend ? () => onAsk(reward) : null,
              ),
            ),
          ),
        if (requests.isNotEmpty) ...[
          const SizedBox(height: NestSpace.lg),
          const NestSectionHeader(title: PointsCopy.kidAskedTitle),
          const SizedBox(height: NestSpace.sm),
          for (final request in requests)
            Padding(
              key: ValueKey(request.id),
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: NestCard(
                variant: NestCardVariant.flat,
                child: Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      request.title ?? PointsCopy.kidRequestUntitled,
                      style: nest.text.bodyStrong,
                    ),
                    RequestStatusTag(request: request),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
