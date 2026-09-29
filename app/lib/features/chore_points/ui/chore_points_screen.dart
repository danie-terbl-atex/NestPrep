import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../model/points_board.dart';
import '../model/reward.dart';
import '../state/chore_points_controller.dart';
import 'kid_balance_card.dart';
import 'point_history_sheet.dart';
import 'reward_sheet.dart';
import 'reward_shelf_section.dart';
import 'spend_for_sheet.dart';
import 'waiting_section.dart';

/// Stars and rewards, for a parent (todos ADR-0003): what is waiting for a
/// look, each child's stars, and the shelf. Pushed from the to-dos tab, so it
/// carries its own way back (`FE-17`).
///
/// The board is never replaced by an empty state: every section says in place
/// when it has nothing, because the shelf's add button and the waiting list
/// are the way in on a household that has not started yet (`FE-08`).
class ChorePointsScreen extends StatelessWidget {
  const ChorePointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChorePointsController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: PointsCopy.screenTitle,
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<PointsBoard>(
              state: controller.board,
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, board) =>
                  _Board(board: board, controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.board, required this.controller});

  final PointsBoard board;
  final ChorePointsController controller;

  @override
  Widget build(BuildContext context) {
    final view = context.watch<HouseholdView>();
    final today = context.read<HouseholdClock>().today;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestRiseIn(
          child: WaitingSection(
            board: board,
            controller: controller,
            members: view.members,
            today: today,
          ),
        ),
        const SizedBox(height: NestSpace.xxl),
        const NestSectionHeader(title: PointsCopy.kidsTitle),
        const SizedBox(height: NestSpace.sm),
        if (board.kids.isEmpty)
          const NestCard(
            variant: NestCardVariant.tinted,
            child: Text(PointsCopy.kidsEmpty),
          ),
        for (final (index, kid) in board.kids.indexed)
          Padding(
            key: ValueKey('kid-${kid.id}'),
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestRiseIn(
              index: index + 1,
              child: KidBalanceCard(
                child: kid,
                balance: board.balanceOf(kid.id),
                today: today,
                onHistory: () => showPointHistorySheet(
                  context: context,
                  householdId: controller.householdId,
                  child: kid,
                ),
                onSpend: board.rewards.isEmpty
                    ? null
                    : () => _spendFor(context, kid),
              ),
            ),
          ),
        const SizedBox(height: NestSpace.xl),
        RewardShelfSection(
          rewards: board.rewards,
          onAdd: () => _editReward(context, null),
          onEdit: (reward) => _editReward(context, reward),
        ),
      ],
    );
  }

  Future<void> _spendFor(BuildContext context, Member kid) async {
    final reward = await showSpendForSheet(
      context: context,
      child: kid,
      balance: board.balanceOf(kid.id),
      rewards: board.rewards,
    );
    if (reward == null || !context.mounted) return;
    final confirmed = await showNestConfirm(
      context: context,
      title: PointsCopy.spendForConfirm(kid.displayName, reward.title),
      message: PointsCopy.spendForBody(reward.cost),
      confirmLabel: PointsCopy.spendForYes,
      cancelLabel: AppCopy.back,
    );
    if (confirmed != true) return;
    await controller.spendFor(kid.id, reward);
  }

  Future<void> _editReward(BuildContext context, Reward? existing) async {
    final draft = await showRewardSheet(context: context, existing: existing);
    switch (draft) {
      case null:
        return;
      case RewardDeleted():
        if (existing != null) await controller.deleteReward(existing.id);
      case RewardSaved(:final title, :final cost, :final icon):
        await controller.saveReward(
          rewardId: existing?.id,
          title: title,
          cost: cost,
          icon: icon,
        );
    }
  }
}
