import 'package:flutter/material.dart';

import '../../design/nest_kit.dart';
import '../copy/app_copy.dart';

/// Asks for one new name and comes back null when nobody gave one.
///
/// Renaming a meal and renaming a household are the same question asked twice,
/// which is why it lives here rather than in either (`ENG-02`).
Future<String?> showRenameSheet({
  required BuildContext context,
  required String title,
  required String label,
  required String initial,
}) => showNestSheet<String>(
  context: context,
  title: title,
  builder: (sheetContext) => _RenameBody(label: label, initial: initial),
);

class _RenameBody extends StatefulWidget {
  const _RenameBody({required this.label, required this.initial});

  final String label;
  final String initial;

  @override
  State<_RenameBody> createState() => _RenameBodyState();
}

class _RenameBodyState extends State<_RenameBody> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _name.text.trim();
    // Saving the same name is a write that changes nothing, so it is not
    // offered — and neither is saving nothing at all.
    final canSave = trimmed.isNotEmpty && trimmed != widget.initial.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestTextField(
          label: widget.label,
          controller: _name,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => canSave ? _save() : null,
        ),
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: AppCopy.householdSave,
          onPressed: canSave ? _save : null,
        ),
      ],
    );
  }

  void _save() => Navigator.of(context).pop(_name.text.trim());
}
