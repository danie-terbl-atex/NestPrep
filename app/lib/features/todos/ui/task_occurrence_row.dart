import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../chore_points/ui/chore_stars_tag.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../../household/ui/member_choice_sheet.dart';
import '../model/task_occurrence.dart';
import '../state/todo_controller.dart';
import 'task_sheet.dart';

/// One task on one day. Tapping ticks it; a long press edits the task itself,
/// which is the thing that repeats — so the two gestures cannot be confused.
class TaskOccurrenceRow extends StatelessWidget {
  const TaskOccurrenceRow({
    required this.occurrence,
    required this.today,
    this.showsRoutine = false,
    super.key,
  });

  final TaskOccurrence occurrence;
  final CalendarDate today;
  final bool showsRoutine;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.read<TodoController>();
    final view = context.read<HouseholdView>();
    final isOverdue = occurrence.isOverdue(today);

    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(NestRadius.lg),
        // Hidden rather than refused: a helper who may only look is not
        // offered a tick the rules would turn down (household ADR-0003).
        onTap: controller.canTick
            ? () => controller.setDone(occurrence, isDone: !occurrence.isDone)
            : null,
        onLongPress: controller.canEdit
            ? () => _edit(context, controller, view)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(NestSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                checked: occurrence.isDone,
                label: occurrence.task.title,
                excludeSemantics: true,
                child: Icon(
                  occurrence.isDone
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: occurrence.isDone
                      ? nest.colors.success
                      : isOverdue
                      ? nest.colors.warning
                      : nest.colors.outlineStrong,
                  size: NestSize.iconLarge,
                ),
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      occurrence.task.title,
                      style: nest.text.bodyStrong.copyWith(
                        color: occurrence.isDone
                            ? nest.colors.inkTertiary
                            : nest.colors.ink,
                        decoration: occurrence.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: NestSpace.xxs),
                    if (occurrence.task.carriesStars) ...[
                      ChoreStarsTag(task: occurrence.task),
                      const SizedBox(height: NestSpace.xxs),
                    ],
                    Text(
                      _subtitle(view),
                      style: nest.text.caption.copyWith(
                        color: isOverdue
                            ? nest.colors.warning
                            : nest.colors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_completableForSomebodyElse(view)) ...[
                NestIconButton(
                  icon: Icons.how_to_reg_outlined,
                  label: AppCopy.todosCompleteFor,
                  variant: NestIconButtonVariant.plain,
                  onPressed: () =>
                      _completeForSomebody(context, controller, view),
                ),
                const SizedBox(width: NestSpace.xs),
              ],
              _AssigneeAvatars(occurrence: occurrence, view: view),
            ],
          ),
        ),
      ),
    );
  }

  /// An admin may tick something off for a profile nobody has claimed — a
  /// child's task, done by a parent (household ADR-0001, todos ADR-0001). The
  /// rules allow exactly that and no more, so the button appears in exactly
  /// that case: an admin, an unfinished task, and at least one assignee who
  /// has not joined.
  ///
  /// It is a button rather than a different meaning for the tap, because the
  /// tap has to stay the fast thing it is.
  bool _completableForSomebodyElse(HouseholdView view) =>
      view.viewerIsAdmin &&
      !occurrence.isDone &&
      _unclaimedAssignees(view).isNotEmpty;

  List<Member> _unclaimedAssignees(HouseholdView view) => [
    for (final id in occurrence.assigneeIds)
      if (view.memberById(id) case final member? when !member.isClaimed) member,
  ];

  Future<void> _completeForSomebody(
    BuildContext context,
    TodoController controller,
    HouseholdView view,
  ) async {
    final candidates = _unclaimedAssignees(view);
    // One unclaimed assignee is not a choice; asking would be ceremony.
    final member = candidates.length == 1
        ? candidates.single
        : await showMemberChoiceSheet(
            context: context,
            title: AppCopy.todosCompleteFor,
            members: candidates,
          );
    if (member == null) return;
    await controller.setDone(occurrence, isDone: true, forMemberId: member.id);
  }

  /// When it is for, who it is for, and which routine it came from — never a
  /// colour on its own (`FE-13`).
  String _subtitle(HouseholdView view) {
    final parts = <String>[NestDates.relative(occurrence.date, today)];
    if (occurrence.isOverdue(today)) parts.insert(0, AppCopy.todosOverdue);
    if (occurrence.isForAnyone) {
      parts.add(AppCopy.todosAnyone);
    } else {
      parts.addAll([
        for (final id in occurrence.assigneeIds)
          ?view.memberById(id)?.displayName,
      ]);
    }
    final doneFor = occurrence.completion?.completedFor;
    if (doneFor != null && doneFor != occurrence.completion?.completedBy) {
      final member = view.memberById(doneFor);
      if (member != null) {
        parts.add('${AppCopy.todosDoneFor} ${member.displayName}');
      }
    }
    if (showsRoutine && occurrence.routine != null) {
      parts.add(occurrence.routine!.name);
    }
    return parts.join(' · ');
  }

  Future<void> _edit(
    BuildContext context,
    TodoController controller,
    HouseholdView view,
  ) async {
    final board = switch (controller.board) {
      AsyncData(value: final value) => value,
      _ => null,
    };
    final draft = await showTaskSheet(
      context: context,
      members: view.members,
      routines: board?.routines ?? const [],
      today: today,
      existing: occurrence.task,
      canSetStars: view.permissions.isFamily,
    );
    switch (draft) {
      case null:
        return;
      case TaskDeleted():
        await controller.deleteTask(occurrence.task.id);
      case TaskSaved():
        await controller.saveTask(
          taskId: occurrence.task.id,
          title: draft.title,
          note: draft.note,
          dueDate: draft.dueDate,
          recurrence: draft.recurrence,
          assigneeIds: draft.assigneeIds,
          routineId: draft.routineId,
          points: draft.points,
          needsApproval: draft.needsApproval,
        );
    }
  }
}

class _AssigneeAvatars extends StatelessWidget {
  const _AssigneeAvatars({required this.occurrence, required this.view});

  final TaskOccurrence occurrence;
  final HouseholdView view;

  @override
  Widget build(BuildContext context) {
    if (occurrence.isForAnyone) return const SizedBox.shrink();
    final members = [
      for (final id in occurrence.assigneeIds) ?view.memberById(id),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final member in members.take(3))
          Padding(
            padding: const EdgeInsets.only(left: NestSpace.xxs),
            child: NestAvatar(
              name: member.displayName,
              color: member.color,
              size: NestSize.avatarSmall,
            ),
          ),
      ],
    );
  }
}
