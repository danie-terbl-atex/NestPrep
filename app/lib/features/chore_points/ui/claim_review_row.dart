import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../data/points_directory.dart';
import '../model/point_claim.dart';

/// A chore a child ticked that waits for a parent's look (todos ADR-0003):
/// who, what, which day and what it is worth, with the two answers side by
/// side. While an answer is on its way both buttons rest, so a second tap
/// cannot send it twice (`FE-10`).
class ClaimReviewRow extends StatelessWidget {
  const ClaimReviewRow({
    required this.claim,
    required this.child,
    required this.today,
    required this.isBusy,
    required this.onReview,
    super.key,
  });

  final PointClaim claim;

  /// The kid profile the stars are for; null if the profile has gone.
  final Member? child;
  final CalendarDate today;
  final bool isBusy;
  final ValueChanged<ChoreReview> onReview;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final who = child;
    return NestCard(
      variant: NestCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (who != null) ...[
                NestAvatar(name: who.displayName, color: who.color),
                const SizedBox(width: NestSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(claim.title, style: nest.text.bodyStrong),
                    Text(
                      [
                        ?who?.displayName,
                        NestDates.relative(claim.occurrenceDate, today),
                      ].join(' · '),
                      style: nest.text.caption,
                    ),
                    const SizedBox(height: NestSpace.xs),
                    NestTag(
                      label: PointsCopy.starsCount(claim.points),
                      tone: NestTagTone.warning,
                      icon: Icons.star_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.md),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              NestButton(
                label: PointsCopy.reviewApprove,
                icon: Icons.check_rounded,
                size: NestButtonSize.small,
                isExpanded: false,
                isLoading: isBusy,
                onPressed: isBusy ? null : () => onReview(ChoreReview.approve),
              ),
              NestButton(
                label: PointsCopy.reviewSendBack,
                icon: Icons.replay_rounded,
                variant: NestButtonVariant.outline,
                size: NestButtonSize.small,
                isExpanded: false,
                onPressed: isBusy ? null : () => onReview(ChoreReview.sendBack),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
