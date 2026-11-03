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

/// One task on one day. A tap opens it on its actions, so a stray tap never
/// ticks anything; a long press still edits the task itself.
class TaskOccurrenceRow extends StatefulWidget {
  const TaskOccurrenceRow({
    required this.occurrence,
    required this.today,
    this.rowId,
    this.showsRoutine = false,
    this.showsDoneAgo = false,
    this.creditTo,
    this.onCompleted,
    super.key,
  });

  final TaskOccurrence occurrence;
  final CalendarDate today;

  /// The same occurrence can show twice on one screen, under two children.
  final String? rowId;
  final bool showsRoutine;
  final bool showsDoneAgo;
  final Member? creditTo;
  final ValueChanged<TaskOccurrence>? onCompleted;

  @override
  State<TaskOccurrenceRow> createState() => _TaskOccurrenceRowState();
}

class _TaskOccurrenceRowState extends State<TaskOccurrenceRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick = AnimationController(vsync: this);
  late final TodoController _controller = context.read<TodoController>();
  bool _isTicking = false;
  ({String? forMemberId})? _pending;

  TaskOccurrence get _occurrence => widget.occurrence;
  String get _rowId => widget.rowId ?? _occurrence.key;
  bool get _looksDone => _occurrence.isDone || _isTicking;

  @override
  void didUpdateWidget(TaskOccurrenceRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_occurrence.isDone) _isTicking = false;
  }

  @override
  void dispose() {
    // Leaving mid-tick still finishes what was asked; nothing is left to
    // tell, so it is written without the toast.
    _write(announce: false);
    _tick.dispose();
    super.dispose();
  }

  ({String? forMemberId})? get _completion {
    if (!_controller.canTick) return null;
    final kid = widget.creditTo;
    if (kid == null) return (forMemberId: null);
    if (_controller.isAdmin) {
      return (forMemberId: kid.id == _controller.memberId ? null : kid.id);
    }
    if (_occurrence.isFor(_controller.memberId)) return (forMemberId: null);
    return null;
  }

  void _complete({String? forMemberId}) {
    _controller.closeRow();
    setState(() => _isTicking = true);
    _pending = (forMemberId: forMemberId);
    _tick
      ..duration = NestMotion.of(context).tick
      ..forward(from: 0).then((_) => _write(announce: true));
  }

  void _write({required bool announce}) {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    final occurrence = _occurrence;
    final controller = _controller;
    controller
        .setDone(occurrence, isDone: true, forMemberId: pending.forMemberId)
        .then((_) {
          if (mounted && controller.actionFailure != null) {
            setState(() => _isTicking = false);
          }
        });
    if (announce) widget.onCompleted?.call(occurrence);
  }

  void _undo() {
    _controller.closeRow();
    _controller.setDone(_occurrence, isDone: false);
  }

  @override
  Widget build(BuildContext context) {
    final view = context.read<HouseholdView>();
    final isOpen = context.select<TodoController, bool>(
      (controller) => controller.openRowId == _rowId,
    );
    final isOverdue = _occurrence.isOverdue(widget.today) && !_isTicking;
    final actions = _actions(context, view);

    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(NestRadius.lg),
        onTap: actions.isEmpty ? null : () => _controller.toggleRow(_rowId),
        onLongPress: _controller.canEdit ? () => _edit(context, view) : null,
        child: Padding(
          padding: const EdgeInsets.all(NestSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    checked: _looksDone,
                    label: _occurrence.task.title,
                    excludeSemantics: true,
                    child: _TickCircle(
                      isDone: _looksDone,
                      isOverdue: isOverdue,
                    ),
                  ),
                  const SizedBox(width: NestSpace.md),
                  Expanded(
                    child: _Details(
                      occurrence: _occurrence,
                      subtitle: _subtitle(view),
                      looksDone: _looksDone,
                      isOverdue: isOverdue,
                    ),
                  ),
                  _AssigneeAvatars(occurrence: _occurrence, view: view),
                ],
              ),
              _Reveal(
                child: isOpen && actions.isNotEmpty
                    ? Padding(
                        key: const ValueKey('actions'),
                        padding: const EdgeInsets.only(
                          top: NestSpace.md,
                          left: NestSize.iconLarge + NestSpace.md,
                        ),
                        child: Wrap(
                          spacing: NestSpace.sm,
                          runSpacing: NestSpace.sm,
                          children: actions,
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, HouseholdView view) {
    final completion = _completion;
    return [
      if (!_looksDone && completion != null)
        NestButton(
          label: AppCopy.todosComplete,
          icon: LucideIcons.check,
          size: NestButtonSize.small,
          isExpanded: false,
          onPressed: () => _complete(forMemberId: completion.forMemberId),
        ),
      if (_occurrence.isDone && _controller.canTick)
        NestButton(
          label: AppCopy.todosNotDone,
          icon: LucideIcons.undo2,
          variant: NestButtonVariant.outline,
          size: NestButtonSize.small,
          isExpanded: false,
          onPressed: _undo,
        ),
      if (widget.creditTo == null && _completableForSomebodyElse(view))
        NestButton(
          label: AppCopy.todosCompleteFor,
          icon: LucideIcons.userCheck,
          variant: NestButtonVariant.tonal,
          size: NestButtonSize.small,
          isExpanded: false,
          onPressed: () => _completeForSomebody(context, view),
        ),
      if (_controller.canEdit)
        NestButton(
          label: AppCopy.todosEdit,
          icon: LucideIcons.pencil,
          variant: NestButtonVariant.ghost,
          size: NestButtonSize.small,
          isExpanded: false,
          onPressed: () {
            _controller.closeRow();
            _edit(context, view);
          },
        ),
    ];
  }

  /// An admin may tick something off for a profile nobody has claimed — a
  /// child's task, done by a parent (household ADR-0001, todos ADR-0001). The
  /// rules allow exactly that and no more, so the button appears in exactly
  /// that case: an admin, an unfinished task, and at least one assignee who
  /// has not joined.
  bool _completableForSomebodyElse(HouseholdView view) =>
      view.viewerIsAdmin && !_looksDone && _unclaimedAssignees(view).isNotEmpty;

  List<Member> _unclaimedAssignees(HouseholdView view) => [
    for (final id in _occurrence.assigneeIds)
      if (view.memberById(id) case final member? when !member.isClaimed) member,
  ];

  Future<void> _completeForSomebody(
    BuildContext context,
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
    if (member == null || !mounted) return;
    _complete(forMemberId: member.id);
  }

  /// When it is for, who it is for, and which routine it came from — never a
  /// colour on its own (`FE-13`).
  String _subtitle(HouseholdView view) {
    final parts = <String>[
      if (widget.showsDoneAgo)
        AppCopy.todosDoneAgo(_doneAgo())
      else
        NestDates.relative(_occurrence.date, widget.today),
    ];
    if (!widget.showsDoneAgo && _occurrence.isOverdue(widget.today)) {
      parts.insert(0, AppCopy.todosOverdue);
    }
    if (_occurrence.isForAnyone) {
      parts.add(AppCopy.todosAnyone);
    } else {
      parts.addAll([
        for (final id in _occurrence.assigneeIds)
          ?view.memberById(id)?.displayName,
      ]);
    }
    final doneFor = _occurrence.completion?.completedFor;
    if (doneFor != null && doneFor != _occurrence.completion?.completedBy) {
      final member = view.memberById(doneFor);
      if (member != null) {
        parts.add('${AppCopy.todosDoneFor} ${member.displayName}');
      }
    }
    if (widget.showsRoutine && _occurrence.routine != null) {
      parts.add(_occurrence.routine!.name);
    }
    return parts.join(' · ');
  }

  String _doneAgo() {
    final at = _occurrence.completion?.completedAt;
    if (at == null) return AppCopy.timeJustNow;
    return NestDates.ago(_controller.now.difference(at));
  }

  Future<void> _edit(BuildContext context, HouseholdView view) async {
    final controller = _controller;
    final board = switch (controller.board) {
      AsyncData(value: final value) => value,
      _ => null,
    };
    final draft = await showTaskSheet(
      context: context,
      members: view.members,
      routines: board?.routines ?? const [],
      today: widget.today,
      existing: _occurrence.task,
      canSetStars: view.permissions.isFamily,
    );
    switch (draft) {
      case null:
        return;
      case TaskDeleted():
        await controller.deleteTask(_occurrence.task.id);
      case TaskSaved():
        await controller.saveTask(
          taskId: _occurrence.task.id,
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

class _Details extends StatelessWidget {
  const _Details({
    required this.occurrence,
    required this.subtitle,
    required this.looksDone,
    required this.isOverdue,
  });

  final TaskOccurrence occurrence;
  final String subtitle;
  final bool looksDone;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: NestMotion.of(context).standard,
          style: nest.text.bodyStrong.copyWith(
            color: looksDone ? nest.colors.inkTertiary : nest.colors.ink,
            decoration: looksDone ? TextDecoration.lineThrough : null,
          ),
          child: Text(occurrence.task.title),
        ),
        const SizedBox(height: NestSpace.xxs),
        if (occurrence.task.carriesStars) ...[
          ChoreStarsTag(task: occurrence.task),
          const SizedBox(height: NestSpace.xxs),
        ],
        Text(
          subtitle,
          style: nest.text.caption.copyWith(
            color: isOverdue ? nest.colors.warning : nest.colors.inkTertiary,
          ),
        ),
      ],
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = NestMotion.of(context);
    // AnimatedSize asserts when its duration is zero, so reduce-motion skips it.
    if (motion.isReduced) return child;
    return AnimatedSize(
      duration: motion.standard,
      curve: NestMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(duration: motion.standard, child: child),
    );
  }
}

class _TickCircle extends StatelessWidget {
  const _TickCircle({required this.isDone, required this.isOverdue});

  final bool isDone;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final motion = NestMotion.of(context);
    final ring = isDone
        ? c.success
        : isOverdue
        ? c.warning
        : c.outlineStrong;
    return AnimatedContainer(
      duration: motion.standard,
      curve: NestMotion.enter,
      width: NestSize.iconLarge,
      height: NestSize.iconLarge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? c.success : Colors.transparent,
        border: Border.all(color: ring, width: NestStroke.focus),
      ),
      child: AnimatedScale(
        scale: isDone ? 1 : 0,
        duration: motion.slow,
        curve: NestMotion.celebrate,
        child: Icon(
          LucideIcons.check,
          size: NestSize.iconSmall,
          color: c.surface,
        ),
      ),
    );
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
