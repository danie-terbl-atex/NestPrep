import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../model/routine.dart';
import '../model/todo_board.dart';
import '../state/todo_controller.dart';
import 'routine_sheet.dart';

/// The household's routines, on the everyone view, so an admin can change a
/// laundry day once instead of six times (todos ADR-0001).
class RoutineList extends StatelessWidget {
  const RoutineList({required this.board, super.key});

  final TodoBoard board;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TodoController>();
    final view = context.read<HouseholdView>();
    if (!controller.isAdmin && board.routines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestSectionHeader(
          title: AppCopy.todosRoutines,
          actionIcon: controller.isAdmin ? LucideIcons.plus : null,
          actionLabel: controller.isAdmin ? AppCopy.todosAddRoutine : null,
          onAction: controller.isAdmin
              ? () => _edit(context, controller, view)
              : null,
        ),
        const SizedBox(height: NestSpace.sm),
        for (final routine in board.routines)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestListRow(
              key: ValueKey(routine.id),
              leading: NestAvatar(name: routine.name, color: routine.color),
              title: routine.name,
              subtitle: AppCopy.recurrenceSummary(routine.recurrence),
              onTap: controller.isAdmin
                  ? () => _edit(context, controller, view, existing: routine)
                  : null,
            ),
          ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    TodoController controller,
    HouseholdView view, {
    Routine? existing,
  }) async {
    final draft = await showRoutineSheet(
      context: context,
      members: view.members,
      today: controller.today,
      existing: existing,
    );
    switch (draft) {
      case null:
        return;
      case RoutineDeleted():
        if (existing != null) await controller.deleteRoutine(existing.id);
      case RoutineSaved():
        await controller.saveRoutine(
          routineId: existing?.id,
          name: draft.name,
          firstDate: draft.firstDate,
          recurrence: draft.recurrence,
          defaultAssigneeIds: draft.defaultAssigneeIds,
          color: draft.color,
        );
    }
  }
}
