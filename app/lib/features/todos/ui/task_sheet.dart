import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/nest_date_field.dart';
import '../../../shared/ui/recurrence_editor.dart';
import '../../chore_points/ui/chore_stars_field.dart';
import '../../household/model/member.dart';
import '../../household/ui/member_picker.dart';
import '../model/routine.dart';
import '../model/task.dart';

/// What the task sheet came back with. Two different outcomes, so two cases
/// rather than one class with fields that mean nothing in half of them
/// (`ENG-09`). Null from `showTaskSheet` means the sheet was closed.
sealed class TaskDraft {
  const TaskDraft();
}

final class TaskSaved extends TaskDraft {
  const TaskSaved({
    required this.title,
    this.note,
    required this.dueDate,
    this.recurrence,
    required this.assigneeIds,
    this.routineId,
    this.points = 0,
    this.needsApproval = false,
  });

  final String title;
  final String? note;
  final CalendarDate dueDate;
  final RecurrenceRule? recurrence;
  final List<String> assigneeIds;
  final String? routineId;

  /// What the chore is worth, and whether a parent checks it first (todos
  /// ADR-0003). Always what the task already had when the sheet did not offer
  /// the choice.
  final int points;
  final bool needsApproval;
}

final class TaskDeleted extends TaskDraft {
  const TaskDeleted();
}

Future<TaskDraft?> showTaskSheet({
  required BuildContext context,
  required List<Member> members,
  required List<Routine> routines,
  required CalendarDate today,
  Task? existing,
  bool canSetStars = false,
}) => showNestSheet<TaskDraft>(
  context: context,
  title: existing == null ? AppCopy.todosAddTask : AppCopy.todosEditTask,
  builder: (sheetContext) => _TaskSheetBody(
    members: members,
    routines: routines,
    today: today,
    existing: existing,
    canSetStars: canSetStars,
  ),
);

class _TaskSheetBody extends StatefulWidget {
  const _TaskSheetBody({
    required this.members,
    required this.routines,
    required this.today,
    required this.existing,
    required this.canSetStars,
  });

  final List<Member> members;
  final List<Routine> routines;
  final CalendarDate today;
  final Task? existing;

  /// Family only: stars are a parent's to give (todos ADR-0003).
  final bool canSetStars;

  @override
  State<_TaskSheetBody> createState() => _TaskSheetBodyState();
}

class _TaskSheetBodyState extends State<_TaskSheetBody> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late CalendarDate _dueDate = widget.existing?.dueDate ?? widget.today;
  late RecurrenceRule? _recurrence = widget.existing?.recurrence;
  late List<String> _assigneeIds = [...?widget.existing?.assigneeIds];
  late String? _routineId = widget.existing?.routineId;
  late int _points = widget.existing?.points ?? 0;
  late bool _needsApproval = widget.existing?.needsApproval ?? false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  /// A task inside a routine follows the routine's schedule, so offering it its
  /// own would be offering a choice that does nothing (todos ADR-0001).
  bool get _followsARoutine => _routineId != null;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    // A starred chore names who earns it — the rules refuse one that does
    // not (todos ADR-0003).
    final canSave =
        _title.text.trim().isNotEmpty &&
        (_points == 0 || _assigneeIds.isNotEmpty);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: AppCopy.todosTitleLabel,
            controller: _title,
            autofocus: widget.existing == null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: AppCopy.todosNoteLabel,
            controller: _note,
            maxLines: 2,
          ),
          if (widget.routines.isNotEmpty) ...[
            const SizedBox(height: NestSpace.xl),
            Text(
              AppCopy.todosRoutineLabel,
              style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
            ),
            const SizedBox(height: NestSpace.sm),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                NestChip(
                  label: AppCopy.todosNoRoutine,
                  isSelected: _routineId == null,
                  onTap: () => setState(() => _routineId = null),
                ),
                for (final routine in widget.routines)
                  NestChip(
                    label: routine.name,
                    isSelected: _routineId == routine.id,
                    onTap: () => setState(() => _routineId = routine.id),
                  ),
              ],
            ),
          ],
          if (!_followsARoutine) ...[
            const SizedBox(height: NestSpace.xl),
            NestDateField(
              label: AppCopy.todosDueLabel,
              value: _dueDate,
              today: widget.today,
              onChanged: (date) => setState(() => _dueDate = date),
            ),
            const SizedBox(height: NestSpace.xl),
            RecurrenceEditor(
              rule: _recurrence,
              firstDate: _dueDate,
              onChanged: (rule) => setState(() => _recurrence = rule),
            ),
          ],
          const SizedBox(height: NestSpace.xl),
          Text(
            AppCopy.todosAssignLabel,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          MemberPicker(
            members: widget.members,
            selectedIds: _assigneeIds,
            onChanged: (ids) => setState(() => _assigneeIds = ids),
          ),
          if (widget.canSetStars) ...[
            const SizedBox(height: NestSpace.xl),
            ChoreStarsField(
              points: _points,
              needsApproval: _needsApproval,
              namesSomebody: _assigneeIds.isNotEmpty,
              onPoints: (points) => setState(() => _points = points),
              onNeedsApproval: (value) =>
                  setState(() => _needsApproval = value),
            ),
          ],
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: AppCopy.householdSave,
            onPressed: canSave ? _save : null,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.householdRemove,
              variant: NestButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(const TaskDeleted()),
            ),
          ],
        ],
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(
      TaskSaved(
        title: _title.text,
        note: _note.text,
        // A task in a routine is filed on the routine's first day; the routine's
        // rule then moves it (todos ADR-0001).
        dueDate: _dueDate,
        recurrence: _followsARoutine ? null : _recurrence,
        assigneeIds: _assigneeIds,
        routineId: _routineId,
        points: _points,
        // A chore worth nothing has nothing to check.
        needsApproval: _points > 0 && _needsApproval,
      ),
    );
  }
}
