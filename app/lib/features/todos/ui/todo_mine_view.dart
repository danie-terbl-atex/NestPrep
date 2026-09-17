import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/todo_board.dart';
import 'task_occurrence_row.dart';

/// What this person is being asked to do: today's, and what has slipped in the
/// last week. Overdue first, because that is what a person wants to see
/// (todos ADR-0001).
class TodoMineView extends StatelessWidget {
  const TodoMineView({required this.board, super.key});

  final TodoBoard board;

  @override
  Widget build(BuildContext context) {
    final overdue = [
      for (final occurrence in board.mine)
        if (occurrence.isOverdue(board.today)) occurrence,
    ];
    final today = [
      for (final occurrence in board.mine)
        if (!occurrence.isOverdue(board.today)) occurrence,
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
      children: [
        if (overdue.isNotEmpty) ...[
          const NestSectionHeader(title: AppCopy.todosOverdue),
          const SizedBox(height: NestSpace.sm),
          for (final occurrence in overdue)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: TaskOccurrenceRow(
                key: ValueKey(occurrence.key),
                occurrence: occurrence,
                today: board.today,
              ),
            ),
          const SizedBox(height: NestSpace.lg),
        ],
        if (today.isNotEmpty) ...[
          const NestSectionHeader(title: AppCopy.todosToday),
          const SizedBox(height: NestSpace.sm),
          for (final occurrence in today)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: TaskOccurrenceRow(
                key: ValueKey(occurrence.key),
                occurrence: occurrence,
                today: board.today,
              ),
            ),
        ],
      ],
    );
  }
}
