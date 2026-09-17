import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/household_shell.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_view.dart';
import '../../household/ui/household_link_button.dart';
import '../model/todo_board.dart';
import '../state/todo_controller.dart';
import 'task_sheet.dart';
import 'todo_everyone_view.dart';
import 'todo_mine_view.dart';

/// Two views over the same occurrences: what this person has to do, and what
/// the household has to do (todos ADR-0001). Which one is showing is local
/// state — it is a lens, not a place, so it is not in the URL (`FE-07`).
class TodoScreen extends StatefulWidget {
  const TodoScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  bool _showingEveryone = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TodoController>();
    final view = context.read<HouseholdView>();
    final failure = controller.actionFailure;

    return NestScaffold(
      title: AppCopy.todosTitle,
      trailing: const [HouseholdLinkButton(), AccountMenuButton()],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.todos,
        onSelect: widget.onSelectTab,
      ),
      floatingAction: Padding(
        padding: const EdgeInsets.only(bottom: NestSize.bottomBarHeight),
        child: NestButton(
          label: AppCopy.todosAddTask,
          icon: Icons.add,
          isExpanded: false,
          onPressed: () => _addTask(context, controller, view),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: NestChip(
                  label: AppCopy.todosMine,
                  isSelected: !_showingEveryone,
                  onTap: () => setState(() => _showingEveryone = false),
                ),
              ),
              const SizedBox(width: NestSpace.sm),
              Expanded(
                child: NestChip(
                  label: AppCopy.todosEveryone,
                  isSelected: _showingEveryone,
                  onTap: () => setState(() => _showingEveryone = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          Expanded(
            child: NestAsyncView<TodoBoard>(
              state: controller.board,
              // The everyone view is its own empty state: it carries the member
              // filter and the routine list, and the first routine is created on
              // a household that has no tasks yet. Replacing it would take away
              // the only way in — the same mistake the grocery suggestions and
              // the meal grid each made once.
              isEmpty: (board) => !_showingEveryone && board.mine.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: AppCopy.todosMineEmptyTitle,
                message: AppCopy.todosMineEmptyBody,
                icon: Icons.check_circle_outline,
              ),
              dataBuilder: (_, board) => _showingEveryone
                  ? TodoEveryoneView(board: board)
                  : TodoMineView(board: board),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTask(
    BuildContext context,
    TodoController controller,
    HouseholdView view,
  ) async {
    final draft = await showTaskSheet(
      context: context,
      members: view.members,
      routines: switch (controller.board) {
        AsyncData(value: final board) => board.routines,
        _ => const [],
      },
      today: controller.today,
    );
    if (draft is! TaskSaved) return;
    await controller.saveTask(
      title: draft.title,
      note: draft.note,
      dueDate: draft.dueDate,
      recurrence: draft.recurrence,
      assigneeIds: draft.assigneeIds,
      routineId: draft.routineId,
    );
  }
}
