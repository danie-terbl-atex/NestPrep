import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../data/house_code_repository.dart';
import '../model/house_code.dart';
import '../model/nanny_limits.dart';

/// What the code sheet decided: a code to save, or — for one that exists —
/// that it goes. Null means closed.
typedef HouseCodeOutcome = ({HouseCodeDraft? draft, bool isRemoval});

/// Adds a house code, or changes one. Both words are needed before it saves;
/// they are kept as typed, tidied only at the ends (`FE-10`).
Future<HouseCodeOutcome?> showHouseCodeSheet({
  required BuildContext context,
  HouseCode? existing,
}) => showNestSheet<HouseCodeOutcome>(
  context: context,
  title: existing == null
      ? NannyBookingCopy.addCode
      : NannyBookingCopy.editCode,
  builder: (_) => _HouseCodeBody(existing: existing),
);

class _HouseCodeBody extends StatefulWidget {
  const _HouseCodeBody({required this.existing});

  final HouseCode? existing;

  @override
  State<_HouseCodeBody> createState() => _HouseCodeBodyState();
}

class _HouseCodeBodyState extends State<_HouseCodeBody> {
  late final _label = TextEditingController(text: widget.existing?.label);
  late final _value = TextEditingController(text: widget.existing?.value);
  late final _note = TextEditingController(text: widget.existing?.note);

  @override
  void dispose() {
    _label.dispose();
    _value.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _label.text.trim().isNotEmpty && _value.text.trim().isNotEmpty;

  void _save() {
    final note = _note.text.trim();
    Navigator.of(context).pop((
      draft: (
        label: _label.text.trim(),
        value: _value.text.trim(),
        note: note.isEmpty ? null : note,
      ),
      isRemoval: false,
    ));
  }

  Future<void> _remove() async {
    final confirmed = await showNestConfirm(
      context: context,
      title: NannyBookingCopy.removeCodeConfirm,
      confirmLabel: NannyCopy.delete,
      cancelLabel: NannyCopy.cancel,
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop((draft: null, isRemoval: true));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: NannyBookingCopy.codeLabel,
            hint: NannyBookingCopy.codeLabelHint,
            controller: _label,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.secretLabel),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyBookingCopy.codeValue,
            hint: NannyBookingCopy.codeValueHint,
            controller: _value,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.secretValue),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: NannyBookingCopy.codeNote,
            hint: NannyBookingCopy.codeNoteHint,
            controller: _note,
            maxLines: 2,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NannyLimits.secretNote),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyBookingCopy.saveCode,
            icon: Icons.check,
            onPressed: _isComplete ? _save : null,
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: NannyBookingCopy.removeCode,
              variant: NestButtonVariant.ghost,
              icon: Icons.delete_outline,
              onPressed: _remove,
            ),
          ],
        ],
      ),
    );
  }
}
