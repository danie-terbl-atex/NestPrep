import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/contact_draft.dart';
import '../model/contact_kind.dart';
import '../model/emergency_contact.dart';
import '../model/nanny_limits.dart';

/// What the contact sheet decided: a contact to save, or — for one that
/// exists — to remove. Null from `showContactSheet` means closed.
typedef ContactOutcome = ({ContactDraft draft, bool isRemoval});

/// Adds a contact, or edits [existing]. The name and number are checked as
/// they are typed against the shape the rules accept, and the save button
/// waits until both are right (`FE-10`).
Future<ContactOutcome?> showContactSheet({
  required BuildContext context,
  EmergencyContact? existing,
}) => showNestSheet<ContactOutcome>(
  context: context,
  title: existing == null ? NannyCopy.addContact : NannyCopy.editContact,
  builder: (_) => _ContactSheetBody(existing: existing),
);

class _ContactSheetBody extends StatefulWidget {
  const _ContactSheetBody({required this.existing});

  final EmergencyContact? existing;

  @override
  State<_ContactSheetBody> createState() => _ContactSheetBodyState();
}

class _ContactSheetBodyState extends State<_ContactSheetBody> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _note = TextEditingController(text: widget.existing?.note);
  late ContactKind _kind = widget.existing?.kind ?? ContactKind.parent;

  bool get _nameIsValid => _name.text.trim().isNotEmpty;
  bool get _phoneIsValid =>
      NannyLimits.phonePattern.hasMatch(_phone.text.trim());

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  ContactDraft get _draft => ContactDraft(
    name: _name.text.trim(),
    kind: _kind,
    phone: _phone.text.trim(),
    note: _note.text,
  );

  Future<void> _remove() async {
    final confirmed = await showNestConfirm(
      context: context,
      title: NannyCopy.removeContactConfirm,
      confirmLabel: NannyCopy.delete,
      cancelLabel: NannyCopy.cancel,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop((draft: _draft, isRemoval: true));
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final phoneTyped = _phone.text.trim().isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            NannyCopy.contactKindLabel,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final kind in ContactKind.values)
                NestChip(
                  label: NannyCopy.contactKindName(kind),
                  isSelected: kind == _kind,
                  icon: kind == _kind ? LucideIcons.check : null,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyCopy.contactName,
            controller: _name,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.contactName),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.sm),
          NestTextField(
            label: NannyCopy.contactPhone,
            hint: NannyCopy.contactPhoneHint,
            controller: _phone,
            keyboardType: TextInputType.phone,
            prefixIcon: LucideIcons.phone,
            errorText: phoneTyped && !_phoneIsValid
                ? NannyCopy.phoneNotValid
                : null,
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.sm),
          NestTextField(
            label: NannyCopy.contactNote,
            hint: NannyCopy.contactNoteHint,
            controller: _note,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.contactNote),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyCopy.save,
            onPressed: _nameIsValid && _phoneIsValid
                ? () =>
                      Navigator.of(context)
                          .pop((draft: _draft, isRemoval: false))
                : null,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: NannyCopy.delete,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.trash2,
              onPressed: _remove,
            ),
          ],
        ],
      ),
    );
  }
}
