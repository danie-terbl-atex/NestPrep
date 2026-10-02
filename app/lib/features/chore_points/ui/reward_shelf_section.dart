import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../model/reward.dart';
import 'reward_icon_glyph.dart';

/// The household's reward shelf as a parent edits it (todos ADR-0003). The
/// add button is in the section header, so an empty shelf still has its way in
/// (`FE-08`).
class RewardShelfSection extends StatelessWidget {
  const RewardShelfSection({
    required this.rewards,
    required this.onAdd,
    required this.onEdit,
    super.key,
  });

  final List<Reward> rewards;
  final VoidCallback onAdd;
  final ValueChanged<Reward> onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestSectionHeader(
          title: PointsCopy.rewardsTitle,
          actionIcon: LucideIcons.plus,
          actionLabel: PointsCopy.rewardAdd,
          onAction: onAdd,
        ),
        const SizedBox(height: NestSpace.sm),
        if (rewards.isEmpty)
          NestCard(
            variant: NestCardVariant.tinted,
            child: Text(
              PointsCopy.rewardsEmpty,
              style: nest.text.bodySecondary,
            ),
          ),
        for (final reward in rewards)
          Padding(
            key: ValueKey(reward.id),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestCard(
              variant: NestCardVariant.flat,
              padding: EdgeInsets.zero,
              child: NestListRow(
                leading: NestIconTile(
                  icon: reward.icon.glyph,
                  tint: reward.icon.tint,
                ),
                title: reward.title,
                subtitle: PointsCopy.starsCount(reward.cost),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () => onEdit(reward),
              ),
            ),
          ),
      ],
    );
  }
}
