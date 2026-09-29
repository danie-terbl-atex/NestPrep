import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/pick_minute_of_day.dart';
import '../model/care_routine.dart';
import '../model/nanny_limits.dart';

/// Edits a child's routine: each step a line of what happens, an optional
/// time from the platform's picker, and an optional how. Null when the person
/// closed the sheet without saving.
Future<List<CareRoutine>?> showRoutineSheet({
  required BuildContext context,
  required List<CareRoutine> routines,
}) => showNestSheet<List<CareRoutine>>(
  context: context,
  title: NannyCopy.editRoutine,
  builder: (_) => _RoutineSheetBody(routines: routines),
);

class _Step {
  _Step(CareRoutine routine)
    : label = TextEditingController(text: routine.label),
      note = TextEditingController(text: routine.note ?? ''),
      minute = routine.minuteOfDay;

  _Step.blank()
    : label = TextEditingController(),
      note = TextEditingController();

  final TextEditingController label;
  final TextEditingController note;
  int? minute;

  CareRoutine get routine =>
      CareRoutine(label: label.text, minuteOfDay: minute, note: note.text);

  void dispose() {
    label.dispose();
    note.dispose();
  }
}

class _RoutineSheetBody extends StatefulWidget {
  const _RoutineSheetBody({required this.routines});

  final List<CareRoutine> routines;

  @override
  State<_RoutineSheetBody> createState() => _RoutineSheetBodyState();
}

class _RoutineSheetBodyState extends State<_RoutineSheetBody> {
  late final List<_Step> _steps = [
    for (final routine in widget.routines) _Step(routine),
    if (widget.routines.isEmpty) _Step.blank(),
  ];

  bool get _isFull => _steps.length >= NannyLimits.routines;

  @override
  void dispose() {
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(_Step step) async {
    final minute = await pickMinuteOfDay(
      context,
      initialMinutes: step.minute ?? 17 * 60,
    );
    if (minute == null || !mounted) return;
    setState(() => step.minute = minute);
  }

  void _remove(_Step step) {
    setState(() => _steps.remove(step));
    step.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final step in _steps)
            _StepEditor(
              key: ObjectKey(step),
              step: step,
              onPickTime: () => _pickTime(step),
              onClearTime: () => setState(() => step.minute = null),
              onRemove: () => _remove(step),
            ),
          if (_isFull)
            Text(
              NannyCopy.limitReached(NannyLimits.routines),
              style: NestTheme.of(context).text.caption,
            )
          else
            NestButton(
              label: NannyCopy.addStep,
              icon: Icons.add,
              variant: NestButtonVariant.outline,
              onPressed: () => setState(() => _steps.add(_Step.blank())),
            ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: NannyCopy.save,
            onPressed: () =>
                Navigator.of(context)
                    .pop([for (final step in _steps) step.routine]),
          ),
        ],
      ),
    );
  }
}

class _StepEditor extends StatelessWidget {
  const _StepEditor({
    required this.step,
    required this.onPickTime,
    required this.onClearTime,
    required this.onRemove,
    super.key,
  });

  final _Step step;
  final VoidCallback onPickTime;
  final VoidCallback onClearTime;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final minute = step.minute;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: NestCard(
        variant: NestCardVariant.tinted,
        padding: const EdgeInsets.all(NestSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: NestTextField(
                    label: NannyCopy.routineStep,
                    hint: NannyCopy.routineStepHint,
                    controller: step.label,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        NannyLimits.routineLabel,
                      ),
                    ],
                  ),
                ),
                NestIconButton(
                  icon: Icons.delete_outline,
                  label: NannyCopy.removeStep,
                  variant: NestIconButtonVariant.plain,
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: NestSpace.sm),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                NestChip(
                  label: minute == null
                      ? NannyCopy.pickTime
                      : NestDates.timeOfDay(minute),
                  icon: Icons.schedule,
                  isSelected: minute != null,
                  semanticLabel: NannyCopy.routineTime,
                  onTap: onPickTime,
                ),
                if (minute != null)
                  NestChip(label: NannyCopy.clearTime, onTap: onClearTime),
              ],
            ),
            const SizedBox(height: NestSpace.sm),
            NestTextField(
              label: NannyCopy.routineNote,
              controller: step.note,
              maxLines: 2,
              inputFormatters: [
                LengthLimitingTextInputFormatter(NannyLimits.routineNote),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
