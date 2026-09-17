import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/household_view.dart';
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
        onTap: () => controller.setDone(occurrence, isDone: !occurrence.isDone),
        onLongPress: () => _edit(context, controller, view),
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
              _AssigneeAvatars(occurrence: occurrence, view: view),
            ],
          ),
        ),
      ),
    );
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
