import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/pick_minute_of_day.dart';
import '../model/medication.dart';
import 'sheet_label.dart';
import 'sheet_outcome.dart';

/// Adds a medicine, or edits [existing]: its name, dose, the times of day a
/// parent set, and a note. No times is a when-needed medicine.
Future<SheetOutcome<Medication>?> showMedicationSheet({
  required BuildContext context,
  Medication? existing,
}) => showNestSheet<SheetOutcome<Medication>>(
  context: context,
  title: existing == null
      ? FamilyCopy.addMedication
      : FamilyCopy.editMedication,
  builder: (_) => _MedicationSheetBody(existing: existing),
);

class _MedicationSheetBody extends StatefulWidget {
  const _MedicationSheetBody({required this.existing});

  final Medication? existing;

  @override
  State<_MedicationSheetBody> createState() => _MedicationSheetBodyState();
}

class _MedicationSheetBodyState extends State<_MedicationSheetBody> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _dose = TextEditingController(text: widget.existing?.dose ?? '');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late List<int> _times = widget.existing?.timesInOrder ?? const [];

  /// Where a new time starts in the picker: breakfast, the most common first
  /// dose, and an hour after the last one after that.
  static const _firstSuggestion = 7 * 60;

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final initial = _times.isEmpty
        ? _firstSuggestion
        : (_times.last + 60) % Medication.minutesInADay;
    final picked = await pickMinuteOfDay(context, initialMinutes: initial);
    if (picked == null || !mounted) return;
    setState(() => _times = ({..._times, picked}.toList()..sort()));
  }

  Medication get _medication => Medication(
    name: _name.text.trim(),
    dose: _dose.text.trim().isEmpty ? null : _dose.text.trim(),
    note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    times: _times,
  );

  @override
  Widget build(BuildContext context) {
    final canSave = _name.text.trim().isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: FamilyCopy.medicationName,
            hint: FamilyCopy.medicationNameHint,
            controller: _name,
            autofocus: widget.existing == null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: FamilyCopy.medicationDose,
            hint: FamilyCopy.medicationDoseHint,
            controller: _dose,
          ),
          const SizedBox(height: NestSpace.xl),
          const SheetLabel(FamilyCopy.medicationTimes),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final minutes in _times)
                NestChip(
                  key: ValueKey(minutes),
                  label: NestDates.timeOfDay(minutes),
                  icon: Icons.schedule,
                  trailingIcon: Icons.close,
                  semanticLabel: FamilyCopy.removeTime(
                    NestDates.timeOfDay(minutes),
                  ),
                  onTap: () => setState(
                    () => _times = _times.where((t) => t != minutes).toList(),
                  ),
                ),
              NestChip(
                label: FamilyCopy.medicationAddTime,
                icon: Icons.add,
                onTap: _addTime,
              ),
            ],
          ),
          if (_times.isEmpty) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              FamilyCopy.medicationWhenNeededHint,
              style: NestTheme.of(context).text.caption,
            ),
          ],
          const SizedBox(height: NestSpace.xl),
          NestTextField(
            label: FamilyCopy.medicationNote,
            hint: FamilyCopy.medicationNoteHint,
            controller: _note,
            maxLines: 3,
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: FamilyCopy.save,
            onPressed: canSave
                ? () => Navigator.of(context).pop(SheetSaved(_medication))
                : null,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: FamilyCopy.remove,
              variant: NestButtonVariant.ghost,
              icon: Icons.delete_outline,
              onPressed: () =>
                  Navigator.of(context).pop(const SheetRemoved<Medication>()),
            ),
          ],
        ],
      ),
    );
  }
}
