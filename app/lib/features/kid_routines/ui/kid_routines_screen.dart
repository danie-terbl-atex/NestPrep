import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../avatars/ui/member_avatar.dart';
import '../../household/model/member.dart';
import '../model/kid_routine.dart';
import '../model/kid_routine_board.dart';
import '../model/kid_routine_draft.dart';
import '../model/kid_routine_slot.dart';
import '../state/kid_routines_controller.dart';
import 'kid_routine_card.dart';
import 'kid_routine_sheet.dart';
import 'kid_routine_slot_look.dart';

/// The children's routines, for a parent (kid-routines ADR-0001): each child,
/// and under them the morning, the afternoon and bedtime — a routine to
/// change, or the way to set one up from a ready-made start.
class KidRoutinesScreen extends StatelessWidget {
  const KidRoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KidRoutinesController>();
    final failure = controller.actionFailure;
    final isOn = context.watch<FeatureFlagsController>().isOn(
      FeatureFlag.kidRoutines,
    );
    return NestScaffold(
      title: KidRoutineCopy.title,
      subtitle: KidRoutineCopy.subtitle,
      leading: backLeading(context),
      body: !isOn
          ? const NestEmptyView(
              title: KidRoutineCopy.switchedOffTitle,
              message: KidRoutineCopy.switchedOffBody,
              icon: LucideIcons.toggleLeft,
            )
          : Column(
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
                  child: NestAsyncView<KidRoutineBoard>(
                    state: controller.board,
                    isEmpty: (board) => board.kids.isEmpty,
                    onRetry: controller.retry,
                    emptyBuilder: (_) => const NestEmptyView(
                      title: KidRoutineCopy.noKidsTitle,
                      message: KidRoutineCopy.noKidsBody,
                      icon: LucideIcons.baby,
                    ),
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

  final KidRoutineBoard board;
  final KidRoutinesController controller;

  Future<void> _open(BuildContext context, KidRoutineDraft draft) async {
    final today = context.read<HouseholdClock>().today;
    final outcome = await showKidRoutineSheet(
      context: context,
      draft: draft,
      kids: board.kids,
      setsStars: controller.setsStars,
      today: today,
    );
    switch (outcome) {
      case null:
        return;
      case KidRoutineSaved(draft: final saved):
        await controller.save(saved);
      case KidRoutineCopied(draft: final copy):
        if (context.mounted) await _open(context, copy);
      case KidRoutineDeleted():
        final routineId = draft.id;
        if (routineId == null || !context.mounted) return;
        final isSure = await showNestConfirm(
          context: context,
          title: KidRoutineCopy.deleteConfirm,
          message: KidRoutineCopy.deleteBody,
          confirmLabel: KidRoutineCopy.deleteRoutine,
          cancelLabel: AppCopy.householdCancel,
          isDangerous: true,
        );
        if (isSure ?? false) await controller.delete(routineId);
    }
  }

  void _setUp(BuildContext context, Member kid, KidRoutineSlot slot) => _open(
    context,
    KidRoutineDraft.starting(
      slot: slot,
      today: context.read<HouseholdClock>().today,
      name: KidRoutineCopy.slotName(slot),
      starters: KidRoutineCopy.starters(slot),
      kidIds: {kid.id},
    ),
  );

  @override
  Widget build(BuildContext context) {
    final canEdit = controller.canEdit;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final (index, kid) in board.kids.indexed)
          Padding(
            key: ValueKey('kid-routines-${kid.id}'),
            padding: const EdgeInsets.only(bottom: NestSpace.xxl),
            child: NestRiseIn(
              index: index,
              child: _KidSection(
                kid: kid,
                board: board,
                onEdit: canEdit
                    ? (routine) => _open(context, KidRoutineDraft.of(routine))
                    : null,
                onSetUp: canEdit ? (slot) => _setUp(context, kid, slot) : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _KidSection extends StatelessWidget {
  const _KidSection({
    required this.kid,
    required this.board,
    required this.onEdit,
    required this.onSetUp,
  });

  final Member kid;
  final KidRoutineBoard board;
  final ValueChanged<KidRoutine>? onEdit;
  final ValueChanged<KidRoutineSlot>? onSetUp;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final (onEdit, onSetUp) = (this.onEdit, this.onSetUp);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MemberAvatar(member: kid, size: NestSize.avatarLarge),
            const SizedBox(width: NestSpace.lg),
            Expanded(child: Text(kid.displayName, style: nest.text.title)),
          ],
        ),
        for (final slot in KidRoutineSlot.values) ...[
          const SizedBox(height: NestSpace.lg),
          Row(
            children: [
              Icon(slot.icon, size: NestSize.iconSmall, color: c.inkSecondary),
              const SizedBox(width: NestSpace.sm),
              Text(
                KidRoutineCopy.slotName(slot),
                style: nest.text.label.copyWith(color: c.inkSecondary),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          for (final routine in board.routinesFor(kid.id, slot))
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: KidRoutineCard(
                key: ValueKey('kid-routine-${kid.id}-${routine.id}'),
                routine: routine,
                sharedWith: [
                  for (final other in board.kids)
                    if (other.id != kid.id && routine.kidIds.contains(other.id))
                      other.displayName,
                ],
                onTap: onEdit == null ? null : () => onEdit(routine),
              ),
            ),
          if (onSetUp != null)
            NestChip(
              key: ValueKey('kid-routine-set-up-${kid.id}-${slot.name}'),
              label: board.routinesFor(kid.id, slot).isEmpty
                  ? KidRoutineCopy.setUp(slot)
                  : KidRoutineCopy.addAnother,
              semanticLabel: board.routinesFor(kid.id, slot).isEmpty
                  ? KidRoutineCopy.setUpFor(slot, kid.displayName)
                  : KidRoutineCopy.addAnotherFor(slot, kid.displayName),
              icon: LucideIcons.plus,
              onTap: () => onSetUp(slot),
            ),
        ],
      ],
    );
  }
}
