import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/calendar_date.dart';
import '../../household/model/member.dart';
import '../model/home_care_room.dart';
import '../model/routine/room_routine.dart';
import '../model/routine/routine_draft.dart';
import 'routine_form.dart';

/// What the routine sheet came back with.
sealed class RoutineSheetOutcome {
  const RoutineSheetOutcome();
}

final class RoutineSaved extends RoutineSheetOutcome {
  const RoutineSaved(this.draft);

  final RoutineDraft draft;
}

final class RoutineDeleted extends RoutineSheetOutcome {
  const RoutineDeleted();
}

/// Adds a room routine, or changes one (home-care ADR-0004). What is missing
/// is said under its field once somebody tries to save (`FE-10`).
Future<RoutineSheetOutcome?> showRoutineSheet({
  required BuildContext context,
  required List<HomeCareRoom> rooms,
  required List<Member> helpers,
  required CalendarDate today,
  RoomRoutine? routine,
}) => showNestSheet<RoutineSheetOutcome>(
  context: context,
  title: routine == null
      ? HomeCareRoutineCopy.newRoutine
      : HomeCareRoutineCopy.editRoutine,
  builder: (context) => _RoutineBody(
    initial: routine == null
        ? RoutineDraft.startingOn(today)
        : RoutineDraft.of(routine),
    rooms: rooms,
    helpers: helpers,
    today: today,
  ),
);

class _RoutineBody extends StatefulWidget {
  const _RoutineBody({
    required this.initial,
    required this.rooms,
    required this.helpers,
    required this.today,
  });

  final RoutineDraft initial;
  final List<HomeCareRoom> rooms;
  final List<Member> helpers;
  final CalendarDate today;

  @override
  State<_RoutineBody> createState() => _RoutineBodyState();
}

class _RoutineBodyState extends State<_RoutineBody> {
  late RoutineDraft _draft = widget.initial;
  var _hasTried = false;

  void _save() {
    if (!_draft.isComplete) {
      setState(() => _hasTried = true);
      return;
    }
    Navigator.of(context).pop(RoutineSaved(_draft));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          RoutineForm(
            draft: _draft,
            rooms: widget.rooms,
            helpers: widget.helpers,
            today: widget.today,
            problems: _hasTried ? _draft.problems : const [],
            onChanged: (change) => setState(() => _draft = change(_draft)),
          ),
          NestButton(
            label: AppCopy.householdSave,
            icon: LucideIcons.check,
            onPressed: _save,
          ),
          if (widget.initial.id != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: HomeCareRoutineCopy.deleteRoutine,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.trash2,
              onPressed: () =>
                  Navigator.of(context).pop(const RoutineDeleted()),
            ),
          ],
          const SizedBox(height: NestSpace.lg),
        ],
      ),
    );
  }
}
