import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/weekday_chips.dart';
import '../../todos/ui/chore_picture_field.dart';
import '../../todos/ui/chore_picture_picker.dart';
import '../../todos/ui/chore_picture_view.dart';
import '../model/kid_routine.dart';
import '../model/kid_routine_step.dart';

/// What the step sheet came back with.
sealed class KidRoutineStepOutcome {
  const KidRoutineStepOutcome();
}

final class KidRoutineStepSaved extends KidRoutineStepOutcome {
  const KidRoutineStepSaved(this.step);

  final KidRoutineStep step;
}

final class KidRoutineStepRemoved extends KidRoutineStepOutcome {
  const KidRoutineStepRemoved();
}

/// One step of a kid routine (kid-routines ADR-0001): its words, its sticker,
/// a note and the things to remember under it. [step] is a new step, with its
/// id already chosen, when [isNew].
Future<KidRoutineStepOutcome?> showKidRoutineStepSheet({
  required BuildContext context,
  required KidRoutineStep step,
  required bool isNew,
}) => showNestSheet<KidRoutineStepOutcome>(
  context: context,
  title: isNew ? KidRoutineCopy.newStep : KidRoutineCopy.editStep,
  builder: (_) => _StepBody(initial: step, isNew: isNew),
);

class _StepBody extends StatefulWidget {
  const _StepBody({required this.initial, required this.isNew});

  final KidRoutineStep initial;
  final bool isNew;

  @override
  State<_StepBody> createState() => _StepBodyState();
}

class _StepBodyState extends State<_StepBody> {
  late final _title = TextEditingController(text: widget.initial.title);
  late final _note = TextEditingController(text: widget.initial.note ?? '');
  final _nextPart = TextEditingController();
  late String? _picture = widget.initial.picture;
  late List<KidRoutinePart> _parts = widget.initial.parts;
  String? _openPartId;
  var _hasTried = false;

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _nextPart.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _hasTried = true);
      return;
    }
    final note = _note.text.trim();
    Navigator.of(context).pop(
      KidRoutineStepSaved(
        KidRoutineStep(
          id: widget.initial.id,
          title: title,
          picture: _picture,
          note: note.isEmpty ? null : note,
          parts: _parts,
        ),
      ),
    );
  }

  void _addPart() {
    final text = _nextPart.text.trim();
    if (text.isEmpty || _parts.length >= KidRoutine.partLimit) return;
    final used = _parts.map((part) => part.id).toSet();
    var next = _parts.length + 1;
    while (used.contains('p$next')) {
      next++;
    }
    setState(() {
      _parts = [..._parts, KidRoutinePart(id: 'p$next', text: text)];
      _nextPart.clear();
    });
  }

  void _replacePart(KidRoutinePart next) => setState(() {
    _parts = [for (final part in _parts) part.id == next.id ? next : part];
  });

  void _removePart(String partId) => setState(() {
    _parts = [
      for (final part in _parts)
        if (part.id != partId) part,
    ];
  });

  void _toggleDay(KidRoutinePart part, int weekday) {
    final days = part.weekdays.contains(weekday)
        ? [
            for (final day in part.weekdays)
              if (day != weekday) day,
          ]
        : ([...part.weekdays, weekday]..sort());
    _replacePart(part.copyWith(weekdays: days));
  }

  Future<void> _pickPartPicture(KidRoutinePart part) async {
    final choice = await showChorePicturePicker(
      context: context,
      title: part.text,
      selected: part.picture,
    );
    if (choice == null) return;
    _replacePart(
      KidRoutinePart(
        id: part.id,
        text: part.text,
        picture: choice.id,
        weekdays: part.weekdays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            key: const ValueKey('kid-routine-step-title'),
            label: KidRoutineCopy.stepTitle,
            hint: KidRoutineCopy.stepTitleHint,
            controller: _title,
            autofocus: widget.isNew,
            errorText: _hasTried && _title.text.trim().isEmpty
                ? KidRoutineCopy.stepTitleMissing
                : null,
            inputFormatters: [
              LengthLimitingTextInputFormatter(KidRoutine.stepTitleLimit),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.xl),
          ChorePictureField(
            title: _title.text,
            picture: _picture,
            onChanged: (picture) => setState(() => _picture = picture),
          ),
          const SizedBox(height: NestSpace.xl),
          NestTextField(
            label: KidRoutineCopy.stepNote,
            hint: KidRoutineCopy.stepNoteHint,
            controller: _note,
            inputFormatters: [
              LengthLimitingTextInputFormatter(KidRoutine.noteLimit),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          Text(
            KidRoutineCopy.packList,
            style: nest.text.label.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: NestSpace.xs),
          Text(
            KidRoutineCopy.packListHelp,
            style: nest.text.caption.copyWith(color: c.inkSecondary),
          ),
          for (final part in _parts)
            _PartRow(
              key: ValueKey('kid-routine-part-${part.id}'),
              part: part,
              isOpen: part.id == _openPartId,
              onTap: () => setState(
                () => _openPartId = part.id == _openPartId ? null : part.id,
              ),
              onRemove: () => _removePart(part.id),
              onToggleDay: (weekday) => _toggleDay(part, weekday),
              onPickPicture: () => _pickPartPicture(part),
            ),
          if (_parts.length < KidRoutine.partLimit) ...[
            const SizedBox(height: NestSpace.sm),
            NestTextField(
              key: const ValueKey('kid-routine-part-add'),
              label: KidRoutineCopy.addPart,
              hint: KidRoutineCopy.addPartHint,
              controller: _nextPart,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                LengthLimitingTextInputFormatter(KidRoutine.partTextLimit),
              ],
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _addPart(),
              suffix: NestIconButton(
                icon: LucideIcons.plus,
                label: KidRoutineCopy.addPart,
                variant: NestIconButtonVariant.plain,
                onPressed: _nextPart.text.trim().isEmpty ? null : _addPart,
              ),
            ),
          ],
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: KidRoutineCopy.stepDone,
            icon: LucideIcons.check,
            onPressed: _save,
          ),
          if (!widget.isNew) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: KidRoutineCopy.removeStep,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.trash2,
              onPressed: () =>
                  Navigator.of(context).pop(const KidRoutineStepRemoved()),
            ),
          ],
          const SizedBox(height: NestSpace.lg),
        ],
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.part,
    required this.isOpen,
    required this.onTap,
    required this.onRemove,
    required this.onToggleDay,
    required this.onPickPicture,
    super.key,
  });

  final KidRoutinePart part;
  final bool isOpen;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final ValueChanged<int> onToggleDay;
  final VoidCallback onPickPicture;

  static const _weekdays = [1, 2, 3, 4, 5, 6, 7];

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestListRow(
      title: part.text,
      subtitle: KidRoutineCopy.partDaysSummary(part.weekdays),
      leading: part.picture == null ? null : ChorePictureView(id: part.picture),
      isSelected: isOpen,
      onTap: onTap,
      trailing: NestIconButton(
        icon: LucideIcons.x,
        label: KidRoutineCopy.removePart(part.text),
        variant: NestIconButtonVariant.plain,
        onPressed: onRemove,
      ),
      footer: !isOpen
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  KidRoutineCopy.partDays,
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
                const SizedBox(height: NestSpace.sm),
                WeekdayChips(
                  weekdays: _weekdays,
                  selected: part.weekdays.toSet(),
                  onToggle: onToggleDay,
                  keyPrefix: 'kid-routine-part-${part.id}-day',
                ),
                const SizedBox(height: NestSpace.sm),
                NestChip(
                  label: part.picture == null
                      ? KidRoutineCopy.partPicture
                      : KidRoutineCopy.partPictureChange,
                  icon: LucideIcons.images,
                  onTap: onPickPicture,
                ),
              ],
            ),
    );
  }
}
