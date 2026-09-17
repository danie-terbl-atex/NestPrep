import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/recurrence/recurrence_rule.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../../household/ui/member_colour_picker.dart';
import '../model/routine.dart';
import 'member_picker.dart';
import 'nest_date_field.dart';
import 'recurrence_editor.dart';

/// What the routine sheet came back with.
sealed class RoutineDraft {
  const RoutineDraft();
}

final class RoutineSaved extends RoutineDraft {
  const RoutineSaved({
    required this.name,
    required this.firstDate,
    this.recurrence,
    required this.defaultAssigneeIds,
    required this.color,
  });

  final String name;
  final CalendarDate firstDate;
  final RecurrenceRule? recurrence;
  final List<String> defaultAssigneeIds;
  final MemberColor color;
}

final class RoutineDeleted extends RoutineDraft {
  const RoutineDeleted();
}

/// A routine is a schedule with a name — "Laundry Day Tasks", every Saturday —
/// and every task in it follows it (todos ADR-0001). Only an admin creates one,
/// which the rules also say.
Future<RoutineDraft?> showRoutineSheet({
  required BuildContext context,
  required List<Member> members,
  required CalendarDate today,
  Routine? existing,
}) => showNestSheet<RoutineDraft>(
  context: context,
  title: existing == null ? AppCopy.todosAddRoutine : AppCopy.todosEditRoutine,
  builder: (sheetContext) =>
      _RoutineSheetBody(members: members, today: today, existing: existing),
);

class _RoutineSheetBody extends StatefulWidget {
  const _RoutineSheetBody({
    required this.members,
    required this.today,
    required this.existing,
  });

  final List<Member> members;
  final CalendarDate today;
  final Routine? existing;

  @override
  State<_RoutineSheetBody> createState() => _RoutineSheetBodyState();
}

class _RoutineSheetBodyState extends State<_RoutineSheetBody> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late CalendarDate _firstDate = widget.existing?.firstDate ?? widget.today;
  late RecurrenceRule? _recurrence =
      widget.existing?.recurrence ??
      const RecurrenceRule(frequency: RecurrenceFrequency.weekly);
  late List<String> _assigneeIds = [...?widget.existing?.defaultAssigneeIds];
  late MemberColor _color = widget.existing?.color ?? MemberColor.violet;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final canSave = _name.text.trim().isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: AppCopy.todosRoutineNameLabel,
            controller: _name,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.xl),
          NestDateField(
            label: AppCopy.todosRoutineStartLabel,
            value: _firstDate,
            today: widget.today,
            onChanged: (date) => setState(() => _firstDate = date),
          ),
          const SizedBox(height: NestSpace.xl),
          RecurrenceEditor(
            rule: _recurrence,
            firstDate: _firstDate,
            onChanged: (rule) => setState(() => _recurrence = rule),
          ),
          const SizedBox(height: NestSpace.xl),
          Text(
            AppCopy.todosRoutineDefaultFor,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          MemberPicker(
            members: widget.members,
            selectedIds: _assigneeIds,
            onChanged: (ids) => setState(() => _assigneeIds = ids),
          ),
          const SizedBox(height: NestSpace.xl),
          Text(
            AppCopy.householdMemberColour,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          MemberColourPicker(
            selected: _color,
            onSelect: (color) => setState(() => _color = color),
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: AppCopy.householdSave,
            onPressed: canSave
                ? () => Navigator.of(context).pop(
                    RoutineSaved(
                      name: _name.text,
                      firstDate: _firstDate,
                      recurrence: _recurrence,
                      defaultAssigneeIds: _assigneeIds,
                      color: _color,
                    ),
                  )
                : null,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.householdRemove,
              variant: NestButtonVariant.danger,
              onPressed: () =>
                  Navigator.of(context).pop(const RoutineDeleted()),
            ),
          ],
        ],
      ),
    );
  }
}
