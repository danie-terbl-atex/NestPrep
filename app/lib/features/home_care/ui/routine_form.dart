import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/nest_date_field.dart';
import '../../../shared/ui/recurrence_editor.dart';
import '../../household/model/member.dart';
import '../model/home_care_room.dart';
import '../model/routine/room_routine.dart';
import '../model/routine/routine_cadence.dart';
import '../model/routine/routine_draft.dart';
import 'form_section.dart';
import 'room_kind_look.dart';
import 'routine_cadence_look.dart';
import 'steps_editor.dart';

/// Everything a parent writes about a room routine: its name, the room, who
/// does it, how often — the cadence presets the shared rule, which can then
/// be changed like any other — and the checklist (home-care ADR-0004).
class RoutineForm extends StatefulWidget {
  const RoutineForm({
    required this.draft,
    required this.onChanged,
    required this.rooms,
    required this.helpers,
    required this.problems,
    required this.today,
    super.key,
  });

  final RoutineDraft draft;

  /// A change to make to the draft as it stands when it is made, so two
  /// taps in one frame both land.
  final ValueChanged<RoutineDraft Function(RoutineDraft)> onChanged;
  final List<HomeCareRoom> rooms;
  final List<Member> helpers;
  final List<RoutineDraftProblem> problems;
  final CalendarDate today;

  @override
  State<RoutineForm> createState() => _RoutineFormState();
}

class _RoutineFormState extends State<RoutineForm> {
  late final _name = TextEditingController(text: widget.draft.name);

  RoutineDraft get _draft => widget.draft;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _errorFor(RoutineDraftProblem problem) =>
      widget.problems.contains(problem)
      ? HomeCareRoutineCopy.missing(problem)
      : null;

  @override
  Widget build(BuildContext context) {
    final room = widget.rooms
        .where((candidate) => candidate.id == _draft.roomId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.xl),
          child: NestTextField(
            label: HomeCareRoutineCopy.routineName,
            hint: HomeCareRoutineCopy.routineNameHint,
            controller: _name,
            errorText: _errorFor(RoutineDraftProblem.noName),
            inputFormatters: [
              LengthLimitingTextInputFormatter(RoomRoutine.nameLimit),
            ],
            onChanged: (text) => widget.onChanged((d) => d.withName(text)),
          ),
        ),
        FormSection(
          label: HomeCareRoutineCopy.room,
          errorText: _errorFor(RoutineDraftProblem.noRoom),
          child: _Choices(
            children: [
              for (final room in widget.rooms)
                NestChip(
                  label: room.name,
                  icon: room.kind.icon,
                  isSelected: room.id == _draft.roomId,
                  onTap: () => widget.onChanged((d) => d.withRoom(room.id)),
                ),
            ],
          ),
        ),
        FormSection(
          label: HomeCareRoutineCopy.helper,
          errorText: _errorFor(RoutineDraftProblem.noHelper),
          child: _Choices(
            children: [
              for (final member in widget.helpers)
                NestChip(
                  label: member.displayName,
                  icon: Icons.person_outline,
                  isSelected: member.id == _draft.helperId,
                  onTap: () => widget.onChanged((d) => d.withHelper(member.id)),
                ),
            ],
          ),
        ),
        FormSection(
          label: HomeCareRoutineCopy.cadence,
          child: _Choices(
            children: [
              for (final cadence in RoutineCadence.values)
                NestChip(
                  label: HomeCareRoutineCopy.cadenceName(cadence),
                  icon: cadence.icon,
                  isSelected: cadence == _draft.cadence,
                  onTap: () => widget.onChanged((d) => d.withCadence(cadence)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.xl),
          child: NestDateField(
            label: HomeCareRoutineCopy.startsOn,
            value: _draft.firstDate,
            today: widget.today,
            onChanged: (day) => widget.onChanged((d) => d.withFirstDate(day)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.xl),
          child: RecurrenceEditor(
            rule: _draft.recurrence,
            firstDate: _draft.firstDate,
            onChanged: (rule) =>
                widget.onChanged((d) => d.withRecurrence(rule)),
          ),
        ),
        FormSection(
          label: HomeCareRoutineCopy.items,
          child: StepsEditor(
            steps: _draft.items,
            canAdd: _draft.canAddItem,
            errorText: _errorFor(RoutineDraftProblem.noItems),
            suggestions: HomeCareRoutineCopy.suggestedItems(
              room?.kind,
              _draft.cadence,
            ),
            addLabel: HomeCareRoutineCopy.addItem,
            addHint: HomeCareRoutineCopy.addItemHint,
            onAdd: (text) => widget.onChanged((d) => d.withItemAdded(text)),
            onRemove: (id) => widget.onChanged((d) => d.withoutItem(id)),
          ),
        ),
      ],
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: NestSpace.sm, runSpacing: NestSpace.sm, children: children);
}
