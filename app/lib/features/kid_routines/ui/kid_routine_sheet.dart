import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/points_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../../../shared/ui/pick_minute_of_day.dart';
import '../../../shared/ui/weekday_chips.dart';
import '../../household/model/member.dart';
import '../model/kid_routine.dart';
import '../model/kid_routine_draft.dart';
import '../model/kid_routine_slot.dart';
import '../model/kid_routine_starter.dart';
import '../model/kid_routine_step.dart';
import 'kid_routine_slot_look.dart';
import 'kid_routine_step_sheet.dart';
import 'kid_routine_steps_editor.dart';

/// What the routine sheet came back with.
sealed class KidRoutineSheetOutcome {
  const KidRoutineSheetOutcome();
}

final class KidRoutineSaved extends KidRoutineSheetOutcome {
  const KidRoutineSaved(this.draft);

  final KidRoutineDraft draft;
}

final class KidRoutineDeleted extends KidRoutineSheetOutcome {
  const KidRoutineDeleted();
}

/// The routine as it stood in the sheet, to open again as a new one.
final class KidRoutineCopied extends KidRoutineSheetOutcome {
  const KidRoutineCopied(this.draft);

  final KidRoutineDraft draft;
}

/// Adds a kid routine, or changes one (kid-routines ADR-0001). What is
/// missing is said under its field once somebody tries to save (`FE-10`).
Future<KidRoutineSheetOutcome?> showKidRoutineSheet({
  required BuildContext context,
  required KidRoutineDraft draft,
  required List<Member> kids,
  required bool setsStars,
  required CalendarDate today,
}) => showNestSheet<KidRoutineSheetOutcome>(
  context: context,
  title: draft.id == null
      ? KidRoutineCopy.newRoutine
      : KidRoutineCopy.editRoutine,
  builder: (_) => _RoutineBody(
    initial: draft,
    kids: kids,
    setsStars: setsStars,
    today: today,
  ),
);

class _RoutineBody extends StatefulWidget {
  const _RoutineBody({
    required this.initial,
    required this.kids,
    required this.setsStars,
    required this.today,
  });

  final KidRoutineDraft initial;
  final List<Member> kids;
  final bool setsStars;
  final CalendarDate today;

  @override
  State<_RoutineBody> createState() => _RoutineBodyState();
}

class _RoutineBodyState extends State<_RoutineBody> {
  late KidRoutineDraft _draft = widget.initial;
  late final _name = TextEditingController(text: widget.initial.name);
  var _hasTried = false;

  static const _starChoices = [0, 1, 2, 3, 5, 10, KidRoutine.maxPoints];
  static const _weekdays = [1, 2, 3, 4, 5, 6, 7];
  static const _defaultFinishBy = 7 * 60;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _change(KidRoutineDraft Function(KidRoutineDraft) change) =>
      setState(() => _draft = change(_draft));

  String? _errorFor(KidRoutineDraftProblem problem) =>
      _hasTried && _draft.problems.contains(problem)
      ? KidRoutineCopy.missing(problem)
      : null;

  void _save() {
    if (!_draft.isComplete) {
      setState(() => _hasTried = true);
      return;
    }
    Navigator.of(context).pop(KidRoutineSaved(_draft));
  }

  /// A slot's own name follows the slot; a name somebody wrote stays.
  void _pickSlot(KidRoutineSlot slot) {
    final wasSlotName =
        _name.text.trim() == KidRoutineCopy.slotName(_draft.slot);
    if (wasSlotName) _name.text = KidRoutineCopy.slotName(slot);
    _change((d) => d.withSlot(slot).withName(_name.text));
  }

  Future<void> _pickFinishBy() async {
    final minutes = await pickMinuteOfDay(
      context,
      initialMinutes: _draft.finishBy ?? _defaultFinishBy,
    );
    if (minutes != null) _change((d) => d.withFinishBy(minutes));
  }

  Future<void> _openStep(KidRoutineStep step, {required bool isNew}) async {
    final outcome = await showKidRoutineStepSheet(
      context: context,
      step: step,
      isNew: isNew,
    );
    switch (outcome) {
      case null:
        return;
      case KidRoutineStepSaved(step: final saved):
        _change((d) => d.withStep(saved));
      case KidRoutineStepRemoved():
        _change((d) => d.withoutStep(step.id));
    }
  }

  void _quickAdd(KidRoutineStarter starter) => _change(
    (d) => d.withStep(
      KidRoutineStep(
        id: d.nextStepId,
        title: starter.title,
        picture: starter.picture,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final finishBy = _draft.finishBy;
    final stars = _starChoices.contains(_draft.points)
        ? _starChoices
        : [..._starChoices, _draft.points];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Section(
            label: KidRoutineCopy.slot,
            child: _Choices(
              children: [
                for (final slot in KidRoutineSlot.values)
                  NestChip(
                    key: ValueKey('kid-routine-slot-${slot.name}'),
                    label: KidRoutineCopy.slotName(slot),
                    icon: slot.icon,
                    isSelected: slot == _draft.slot,
                    onTap: () => _pickSlot(slot),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.xl),
            child: NestTextField(
              key: const ValueKey('kid-routine-name'),
              label: KidRoutineCopy.name,
              controller: _name,
              errorText: _errorFor(KidRoutineDraftProblem.noName),
              inputFormatters: [
                LengthLimitingTextInputFormatter(KidRoutine.nameLimit),
              ],
              onChanged: (text) => _change((d) => d.withName(text)),
            ),
          ),
          _Section(
            label: KidRoutineCopy.kids,
            errorText: _errorFor(KidRoutineDraftProblem.noKids),
            child: _Choices(
              children: [
                for (final kid in widget.kids)
                  NestChip(
                    key: ValueKey('kid-routine-kid-${kid.id}'),
                    label: kid.displayName,
                    icon: _draft.kidIds.contains(kid.id)
                        ? LucideIcons.squareCheck
                        : LucideIcons.square,
                    isSelected: _draft.kidIds.contains(kid.id),
                    onTap: () => _change((d) => d.withKidToggled(kid.id)),
                  ),
              ],
            ),
          ),
          _Section(
            label: KidRoutineCopy.days,
            errorText: _errorFor(KidRoutineDraftProblem.noDays),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Choices(
                  children: [
                    for (final (label, days) in const [
                      (KidRoutineCopy.schoolDays, KidRoutineDraft.schoolDays),
                      (KidRoutineCopy.everyDay, KidRoutineDraft.everyDay),
                      (KidRoutineCopy.weekends, KidRoutineDraft.weekend),
                    ])
                      NestChip(
                        label: label,
                        isSelected:
                            KidRoutineCopy.daysSummary(_draft.weekdays) ==
                            label,
                        onTap: () => _change((d) => d.withWeekdays(days)),
                      ),
                  ],
                ),
                const SizedBox(height: NestSpace.md),
                WeekdayChips(
                  weekdays: _weekdays,
                  selected: _draft.weekdays,
                  onToggle: (day) => _change((d) => d.withWeekdayToggled(day)),
                  keyPrefix: 'kid-routine-day',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.xl),
            child: NestListRow(
              key: const ValueKey('kid-routine-finish-by'),
              title: KidRoutineCopy.finishBy,
              subtitle: finishBy == null
                  ? KidRoutineCopy.finishByNone
                  : NestDates.timeOfDay(finishBy),
              leading: const Icon(LucideIcons.clock, size: NestSize.iconMedium),
              onTap: _pickFinishBy,
              trailing: finishBy == null
                  ? null
                  : NestIconButton(
                      icon: LucideIcons.x,
                      label: KidRoutineCopy.finishByClear,
                      variant: NestIconButtonVariant.plain,
                      onPressed: () => _change((d) => d.withFinishBy(null)),
                    ),
            ),
          ),
          if (widget.setsStars)
            _Section(
              label: KidRoutineCopy.stars,
              child: _Choices(
                children: [
                  for (final size in stars)
                    NestChip(
                      key: ValueKey('kid-routine-stars-$size'),
                      label: size == 0
                          ? PointsCopy.choreNoStars
                          : PointsCopy.starsCount(size),
                      icon: size == 0 ? null : LucideIcons.star,
                      isSelected: _draft.points == size,
                      onTap: () => _change((d) => d.withPoints(size)),
                    ),
                ],
              ),
            ),
          _Section(
            label: KidRoutineCopy.steps,
            help: KidRoutineCopy.stepsHelp,
            child: KidRoutineStepsEditor(
              steps: _draft.steps,
              canAdd: _draft.canAddStep,
              errorText: _errorFor(KidRoutineDraftProblem.noSteps),
              quickAdds: [
                ...KidRoutineCopy.starters(_draft.slot),
                ...KidRoutineCopy.extras(_draft.slot),
              ],
              onOpen: (step) => _openStep(step, isNew: false),
              onAdd: () => _openStep(
                KidRoutineStep(id: _draft.nextStepId, title: ''),
                isNew: true,
              ),
              onQuickAdd: _quickAdd,
              onMove: (from, to) => _change((d) => d.withStepMoved(from, to)),
            ),
          ),
          NestButton(
            key: const ValueKey('kid-routine-save'),
            label: AppCopy.householdSave,
            icon: LucideIcons.check,
            onPressed: _save,
          ),
          if (widget.initial.id != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: KidRoutineCopy.makeCopy,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.copy,
              onPressed: () => Navigator.of(context).pop(
                KidRoutineCopied(
                  _draft.asCopy(
                    name: KidRoutineCopy.copyName(_draft.cleanName),
                    today: widget.today,
                  ),
                ),
              ),
            ),
            NestButton(
              label: KidRoutineCopy.deleteRoutine,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.trash2,
              onPressed: () =>
                  Navigator.of(context).pop(const KidRoutineDeleted()),
            ),
          ],
          const SizedBox(height: NestSpace.lg),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.child,
    this.help,
    this.errorText,
  });

  final String label;
  final Widget child;
  final String? help;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final (help, error) = (this.help, errorText);
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: nest.text.label.copyWith(color: c.inkSecondary)),
          if (help != null) ...[
            const SizedBox(height: NestSpace.xs),
            Text(
              help,
              style: nest.text.caption.copyWith(color: c.inkSecondary),
            ),
          ],
          const SizedBox(height: NestSpace.sm),
          child,
          if (error != null) ...[
            const SizedBox(height: NestSpace.xs),
            Text(error, style: nest.text.caption.copyWith(color: c.danger)),
          ],
        ],
      ),
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
