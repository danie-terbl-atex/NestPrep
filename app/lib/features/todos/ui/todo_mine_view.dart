import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/task_occurrence.dart';
import '../model/todo_board.dart';
import 'task_occurrence_row.dart';

/// What this person is being asked to do: today's, and what has slipped in the
/// last week. Overdue first, because that is what a person wants to see
/// (todos ADR-0001). What they finished in the last day stays below it, to
/// see and to undo.
class TodoMineView extends StatelessWidget {
  const TodoMineView({
    required this.board,
    required this.onCompleted,
    super.key,
  });

  final TodoBoard board;
  final ValueChanged<TaskOccurrence> onCompleted;

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
        NestAnimatedColumn<_Item>(
          items: [
            if (board.mine.isEmpty) const _Clear(),
            if (overdue.isNotEmpty) const _Header(AppCopy.todosOverdue),
            for (final occurrence in overdue) _Open(occurrence),
            if (today.isNotEmpty) const _Header(AppCopy.todosToday),
            for (final occurrence in today) _Open(occurrence),
            if (board.justDone.isNotEmpty) const _Header(AppCopy.todosJustDone),
            for (final occurrence in board.justDone) _Done(occurrence),
          ],
          keyOf: (item) => item.key,
          itemBuilder: (context, item) => switch (item) {
            _Clear() => const Padding(
              padding: EdgeInsets.only(bottom: NestSpace.lg),
              child: NestEmptyView(
                title: AppCopy.todosNothingLeftTitle,
                message: AppCopy.todosNothingLeftBody,
                icon: LucideIcons.circleCheck,
              ),
            ),
            _Header(:final title) => Padding(
              padding: const EdgeInsets.only(
                top: NestSpace.sm,
                bottom: NestSpace.sm,
              ),
              child: NestSectionHeader(title: title),
            ),
            _Open(:final occurrence) || _Done(:final occurrence) => Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: TaskOccurrenceRow(
                key: ValueKey(item.key),
                rowId: item.key,
                occurrence: occurrence,
                today: board.today,
                showsDoneAgo: item is _Done,
                onCompleted: onCompleted,
              ),
            ),
          },
        ),
      ],
    );
  }
}

sealed class _Item {
  const _Item();

  String get key;
}

final class _Clear extends _Item {
  const _Clear();

  @override
  String get key => 'clear';
}

final class _Header extends _Item {
  const _Header(this.title);

  final String title;

  @override
  String get key => 'header:$title';
}

final class _Open extends _Item {
  const _Open(this.occurrence);

  final TaskOccurrence occurrence;

  @override
  String get key => occurrence.key;
}

final class _Done extends _Item {
  const _Done(this.occurrence);

  final TaskOccurrence occurrence;

  @override
  String get key => 'done:${occurrence.key}';
}
