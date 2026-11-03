import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/chore_points_route.dart';
import '../../../app/household_shell.dart';
import '../../../app/lists_switch.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../../household/model/household_view.dart';
import '../../notifications/ui/notification_bell.dart';
import '../model/task_occurrence.dart';
import '../model/todo_board.dart';
import '../state/todo_controller.dart';
import 'task_sheet.dart';
import 'todo_chores_view.dart';
import 'todo_everyone_view.dart';
import 'todo_mine_view.dart';

/// Lenses over the same occurrences: what this person has to do, what the
/// household has to do, and the children's chores (todos ADR-0001). Which one
/// is showing is local state — it is a lens, not a place, so it is not in the
/// URL (`FE-07`).
class TodoScreen extends StatefulWidget {
  const TodoScreen({required this.onSelectTab, super.key});

  final ValueChanged<HouseholdTab> onSelectTab;

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

enum _Lens { mine, everyone, chores }

class _TodoScreenState extends State<TodoScreen> {
  _Lens _picked = _Lens.mine;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _undo;

  @override
  void dispose() {
    _undo?.close();
    super.dispose();
  }

  void _show(_Lens lens, TodoController controller) {
    controller.closeRow();
    setState(() => _picked = lens);
  }

  void _offerUndo(TaskOccurrence occurrence) {
    final controller = context.read<TodoController>();
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final undo = messenger.showSnackBar(
      SnackBar(
        content: Text(AppCopy.todosDoneToast(occurrence.task.title)),
        duration: NestMotion.undoWindow,
        persist: false,
        action: SnackBarAction(
          label: AppCopy.todosUndo,
          onPressed: () => controller.setDone(occurrence, isDone: false),
        ),
      ),
    );
    _undo = undo;
    undo.closed.whenComplete(() {
      if (_undo == undo) _undo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TodoController>();
    final view = context.read<HouseholdView>();
    final failure = controller.actionFailure;
    final board = switch (controller.board) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final showsChores = !controller.isOwnOnly && (board?.hasKids ?? false);
    final lens = _picked == _Lens.chores && !showsChores ? _Lens.mine : _picked;

    return NestScaffold(
      title: ListsSwitch.titleFor(view.permissions, AppCopy.todosTitle),
      trailing: [
        // Stars and rewards are a parent's to run (todos ADR-0003).
        if (view.permissions.isFamily)
          NestIconButton(
            icon: LucideIcons.sparkles,
            label: PointsCopy.screenTitle,
            onPressed: () =>
                context.push(ChorePointsRoute.pathFor(view.household.id)),
          ),
        const NotificationBell(),
        const AccountMenuButton(),
      ],
      bottomBar: HouseholdTabBar(
        current: HouseholdTab.todos,
        onSelect: widget.onSelectTab,
      ),
      floatingAction: controller.canEdit
          ? NestButton(
              label: AppCopy.todosAddTask,
              icon: LucideIcons.plus,
              isExpanded: false,
              onPressed: () => _addTask(context, controller, view),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListsSwitch(
            current: HouseholdTab.todos,
            onSelect: widget.onSelectTab,
          ),
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
          // Somebody who may only see their own to-dos has no everyone view
          // to switch to (household ADR-0003).
          if (!controller.isOwnOnly)
            Row(
              children: [
                Expanded(
                  child: NestChip(
                    label: AppCopy.todosMine,
                    isSelected: lens == _Lens.mine,
                    onTap: () => _show(_Lens.mine, controller),
                  ),
                ),
                const SizedBox(width: NestSpace.sm),
                Expanded(
                  child: NestChip(
                    label: AppCopy.todosEveryone,
                    isSelected: lens == _Lens.everyone,
                    onTap: () => _show(_Lens.everyone, controller),
                  ),
                ),
                if (showsChores) ...[
                  const SizedBox(width: NestSpace.sm),
                  Expanded(
                    child: NestChip(
                      label: AppCopy.todosChoresChip(board!.openChoreCount),
                      semanticLabel: AppCopy.todosChoresChipSaid(
                        board.openChoreCount,
                      ),
                      isSelected: lens == _Lens.chores,
                      onTap: () => _show(_Lens.chores, controller),
                    ),
                  ),
                ],
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
              isEmpty: (board) =>
                  lens == _Lens.mine &&
                  board.mine.isEmpty &&
                  board.justDone.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: AppCopy.todosMineEmptyTitle,
                message: AppCopy.todosMineEmptyBody,
                icon: LucideIcons.circleCheck,
              ),
              dataBuilder: (_, board) => switch (lens) {
                _Lens.mine => TodoMineView(
                  board: board,
                  onCompleted: _offerUndo,
                ),
                _Lens.everyone => TodoEveryoneView(
                  board: board,
                  onCompleted: _offerUndo,
                ),
                _Lens.chores => TodoChoresView(
                  board: board,
                  onCompleted: _offerUndo,
                ),
              },
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
      canSetStars: view.permissions.isFamily,
    );
    if (draft is! TaskSaved) return;
    await controller.saveTask(
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
