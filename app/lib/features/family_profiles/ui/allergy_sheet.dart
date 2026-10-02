import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/allergen.dart';
import '../model/allergy.dart';
import '../model/allergy_draft.dart';
import '../model/allergy_severity.dart';
import 'severity_choice.dart';
import 'sheet_label.dart';
import 'sheet_outcome.dart';

/// Adds an allergy, or edits [existing]. Allergens the person already has are
/// not offered again — they are edited where they are ([taken]).
Future<SheetOutcome<AllergyDraft>?> showAllergySheet({
  required BuildContext context,
  required Set<Allergen> taken,
  required bool canAddOther,
  Allergy? existing,
}) => showNestSheet<SheetOutcome<AllergyDraft>>(
  context: context,
  title: existing == null ? FamilyCopy.addAllergy : FamilyCopy.editAllergy,
  builder: (_) => _AllergySheetBody(
    existing: existing,
    taken: taken,
    canAddOther: canAddOther || existing?.otherId != null,
  ),
);

class _AllergySheetBody extends StatefulWidget {
  const _AllergySheetBody({
    required this.existing,
    required this.taken,
    required this.canAddOther,
  });

  final Allergy? existing;
  final Set<Allergen> taken;

  /// False once the free-text allergies are at the rules' limit.
  final bool canAddOther;

  @override
  State<_AllergySheetBody> createState() => _AllergySheetBodyState();
}

class _AllergySheetBodyState extends State<_AllergySheetBody> {
  late Allergen? _allergen = widget.existing?.allergen;
  late bool _isOther = widget.existing != null && _allergen == null;
  late AllergySeverity _severity =
      widget.existing?.severity ?? AllergySeverity.moderate;
  late final _otherName = TextEditingController(
    text: widget.existing?.otherName ?? '',
  );
  late final _note = TextEditingController(text: widget.existing?.note ?? '');

  @override
  void dispose() {
    _otherName.dispose();
    _note.dispose();
    super.dispose();
  }

  List<Allergen> get _offered => [
    for (final allergen in Allergen.values)
      if (!widget.taken.contains(allergen) ||
          allergen == widget.existing?.allergen)
        allergen,
  ];

  AllergyDraft? get _draft {
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final allergen = _allergen;
    if (!_isOther && allergen != null) {
      return AllergyDraft.known(
        allergen: allergen,
        severity: _severity,
        note: note,
      );
    }
    final name = _otherName.text.trim();
    if (!_isOther || name.isEmpty) return null;
    return AllergyDraft.other(otherName: name, severity: _severity, note: note);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetLabel(FamilyCopy.allergenLabel),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final allergen in _offered)
                NestChip(
                  label: FamilyCopy.allergenName(allergen),
                  isSelected: !_isOther && _allergen == allergen,
                  onTap: () => setState(() {
                    _allergen = allergen;
                    _isOther = false;
                  }),
                ),
              if (widget.canAddOther)
                NestChip(
                  label: FamilyCopy.allergenOther,
                  icon: LucideIcons.pencil,
                  isSelected: _isOther,
                  onTap: () => setState(() => _isOther = true),
                ),
            ],
          ),
          if (_isOther) ...[
            const SizedBox(height: NestSpace.lg),
            NestTextField(
              label: FamilyCopy.otherAllergyName,
              hint: FamilyCopy.otherAllergyNameHint,
              controller: _otherName,
              autofocus: widget.existing == null,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: NestSpace.xl),
          const SheetLabel(FamilyCopy.severityLabel),
          SeverityChoice(
            selected: _severity,
            onSelect: (severity) => setState(() => _severity = severity),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: FamilyCopy.allergyNote,
            hint: FamilyCopy.allergyNoteHint,
            controller: _note,
            maxLines: 3,
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: FamilyCopy.save,
            // The draft is read when Save is pressed, not when the sheet last
            // rebuilt: the note has no listener, and a closure over an older
            // draft saved the allergy without the note just typed.
            onPressed: draft == null
                ? null
                : () => Navigator.of(context).pop(SheetSaved(_draft ?? draft)),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: FamilyCopy.remove,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.trash2,
              onPressed: () =>
                  Navigator.of(context).pop(const SheetRemoved<AllergyDraft>()),
            ),
          ],
        ],
      ),
    );
  }
}
