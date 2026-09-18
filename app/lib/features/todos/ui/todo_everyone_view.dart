import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/member_filter.dart';
import '../../household/model/household_view.dart';
import '../model/task_occurrence.dart';
import '../model/todo_board.dart';
import '../state/todo_controller.dart';
import 'routine_list.dart';
import 'task_occurrence_row.dart';

/// The whole household's week, grouped by routine and then by day, filterable
/// by member (todos ADR-0001). The filter is a lens on what is showing, so it
/// lives on the controller and not in the document.
class TodoEveryoneView extends StatelessWidget {
  const TodoEveryoneView({required this.board, super.key});

  final TodoBoard board;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TodoController>();
    final members = context.read<HouseholdView>().members;
    final occurrences = board.everyoneFor(controller.memberFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MemberFilter(
          members: members,
          selectedId: controller.memberFilter,
          onSelect: controller.filterBy,
          everybodyLabel: AppCopy.todosAllMembers,
        ),
        const SizedBox(height: NestSpace.lg),
        RoutineList(board: board),
        const SizedBox(height: NestSpace.lg),
        Expanded(
          child: occurrences.isEmpty
              ? const NestEmptyView(
                  title: AppCopy.todosEveryoneEmptyTitle,
                  message: AppCopy.todosEveryoneEmptyBody,
                  icon: Icons.check_circle_outline,
                )
              : _GroupedList(occurrences: occurrences, board: board),
        ),
      ],
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.occurrences, required this.board});

  final List<TaskOccurrence> occurrences;
  final TodoBoard board;

  @override
  Widget build(BuildContext context) {
    final byDay = <String, List<TaskOccurrence>>{};
    for (final occurrence in occurrences) {
      byDay.putIfAbsent(occurrence.date.iso, () => []).add(occurrence);
    }
    final days = byDay.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight * 2),
      children: [
        for (final day in days) ...[
          NestSectionHeader(
            title: NestDates.dayInARun(byDay[day]!.first.date, board.today),
          ),
          const SizedBox(height: NestSpace.sm),
          for (final occurrence in byDay[day]!)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: TaskOccurrenceRow(
                key: ValueKey(occurrence.key),
                occurrence: occurrence,
                today: board.today,
                showsRoutine: true,
              ),
            ),
          const SizedBox(height: NestSpace.md),
        ],
      ],
    );
  }
}
