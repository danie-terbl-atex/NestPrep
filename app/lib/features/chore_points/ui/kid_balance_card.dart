import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../model/point_balance.dart';

/// One child's stars on the parent's screen (todos ADR-0003): how many, the
/// streak while it lives, what they have earned in all — and the two things a
/// parent does with them: see where they came from, and spend them for a
/// child who has no device of their own.
class KidBalanceCard extends StatelessWidget {
  const KidBalanceCard({
    required this.child,
    required this.balance,
    required this.today,
    required this.onHistory,
    required this.onSpend,
    super.key,
  });

  final Member child;
  final PointBalance balance;
  final CalendarDate today;
  final VoidCallback onHistory;

  /// Null when the shelf is empty — there is nothing to spend on.
  final VoidCallback? onSpend;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final streak = balance.streakOn(today);
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NestAvatar(
                name: child.displayName,
                color: child.color,
                size: NestSize.avatarLarge,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.displayName, style: nest.text.title),
                    Text(
                      PointsCopy.earnedInAll(balance.earned),
                      style: nest.text.caption,
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.star, color: c.warning),
              const SizedBox(width: NestSpace.xs),
              Text('${balance.balance}', style: nest.text.figureSmall),
            ],
          ),
          if (streak >= 2) ...[
            const SizedBox(height: NestSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: NestTag(
                label: PointsCopy.streakDays(streak),
                tone: NestTagTone.warning,
                icon: LucideIcons.flame,
              ),
            ),
          ],
          const SizedBox(height: NestSpace.md),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestButton(
                label: PointsCopy.history,
                icon: LucideIcons.receiptText,
                variant: NestButtonVariant.tonal,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: onHistory,
              ),
              NestButton(
                label: PointsCopy.spendFor,
                icon: LucideIcons.gift,
                variant: NestButtonVariant.outline,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: onSpend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
