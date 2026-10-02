import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/text/normalised_name.dart';
import '../state/family_edits.dart';

/// Likes or dislikes as chips: type one, add it, tap a chip to take it away.
///
/// What is added is trimmed as it lands and shown as it will be saved, and a
/// second "pasta" is simply not added — the person sees the list they are
/// saving, nothing is changed behind them (`FE-10`). It stops at the list's
/// limit and says so.
class ChipListEditor extends StatefulWidget {
  const ChipListEditor({
    required this.label,
    required this.hint,
    required this.values,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String hint;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  State<ChipListEditor> createState() => _ChipListEditorState();
}

class _ChipListEditorState extends State<ChipListEditor> {
  final _input = TextEditingController();

  bool get _isFull => widget.values.length >= FamilyEdits.listLimit;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final value = _input.text.trim();
    if (value.isEmpty || _isFull) return;
    final key = normalisedName(value);
    final isNew = widget.values.every((it) => normalisedName(it) != key);
    _input.clear();
    setState(() {});
    if (isNew) widget.onChanged([...widget.values, value]);
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _input.text.trim().isNotEmpty && !_isFull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: NestTextField(
                label: widget.label,
                hint: widget.hint,
                controller: _input,
                enabled: !_isFull,
                helperText: _isFull ? FamilyCopy.listFull : null,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: NestSpace.sm),
            NestIconButton(
              icon: LucideIcons.plus,
              label: FamilyCopy.addChip,
              variant: NestIconButtonVariant.accent,
              onPressed: canAdd ? _add : null,
            ),
          ],
        ),
        if (widget.values.isNotEmpty) ...[
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final value in widget.values)
                NestChip(
                  key: ValueKey(value),
                  label: value,
                  trailingIcon: LucideIcons.x,
                  semanticLabel: FamilyCopy.removeChip(value),
                  onTap: () => widget.onChanged(
                    widget.values.where((it) => it != value).toList(),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
