import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../model/points_board.dart';
import '../state/chore_points_controller.dart';
import 'claim_review_row.dart';
import 'reward_request_row.dart';

/// Everything waiting for a parent (todos ADR-0003): chores to look at, then
/// rewards to hand over. When nothing waits it says so in place — the section
/// is where the next one will land (`FE-08`).
class WaitingSection extends StatelessWidget {
  const WaitingSection({
    required this.board,
    required this.controller,
    required this.members,
    required this.today,
    super.key,
  });

  final PointsBoard board;
  final ChorePointsController controller;
  final List<Member> members;
  final CalendarDate today;

  Member? _member(String id) =>
      members.where((member) => member.id == id).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestSectionHeader(title: PointsCopy.waitingTitle(board.waitingCount)),
        const SizedBox(height: NestSpace.sm),
        if (board.hasNothingWaiting)
          NestCard(
            variant: NestCardVariant.tinted,
            child: Row(
              children: [
                const NestIconTile(
                  icon: LucideIcons.checkCheck,
                  tint: NestTileTint.basil,
                ),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: Text(
                    PointsCopy.waitingNone,
                    style: nest.text.bodySecondary,
                  ),
                ),
              ],
            ),
          ),
        for (final claim in board.pendingClaims)
          Padding(
            key: ValueKey('claim-${claim.id}'),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: ClaimReviewRow(
              claim: claim,
              child: _member(claim.memberId),
              today: today,
              isBusy: controller.isBusy(claim.id),
              onReview: (decision) => controller.review(claim, decision),
            ),
          ),
        for (final request in board.waitingRequests)
          Padding(
            key: ValueKey('request-${request.id}'),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: RewardRequestRow(
              request: request,
              child: _member(request.memberId),
              isBusy: controller.isBusy(request.id),
              onSettle: (decision) => controller.settle(request, decision),
            ),
          ),
      ],
    );
  }
}
