import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/checklist_item.dart';
import '../model/nanny_limits.dart';
import '../model/shift_moment.dart';

/// Edits one moment's checklist: a line per thing to do. An item keeps its id
/// through an edit, so a tick on an open shift survives a parent fixing its
/// spelling; a new one gets its id when it is saved. Null means closed.
Future<List<ChecklistItem>?> showChecklistSheet({
  required BuildContext context,
  required ShiftMoment moment,
  required List<ChecklistItem> items,
}) => showNestSheet<List<ChecklistItem>>(
  context: context,
  title: NannyCopy.editChecklist(moment),
  builder: (_) => _ChecklistBody(items: items),
);

class _Line {
  _Line(this.id, String text) : text = TextEditingController(text: text);

  /// Empty for a line typed in this sheet.
  final String id;
  final TextEditingController text;
}

class _ChecklistBody extends StatefulWidget {
  const _ChecklistBody({required this.items});

  final List<ChecklistItem> items;

  @override
  State<_ChecklistBody> createState() => _ChecklistBodyState();
}

class _ChecklistBodyState extends State<_ChecklistBody> {
  late final List<_Line> _lines = [
    for (final item in widget.items) _Line(item.id, item.text),
    if (widget.items.isEmpty) _Line('', ''),
  ];

  bool get _isFull => _lines.length >= NannyLimits.checklistItems;

  @override
  void dispose() {
    for (final line in _lines) {
      line.text.dispose();
    }
    super.dispose();
  }

  void _remove(_Line line) {
    setState(() => _lines.remove(line));
    line.text.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in _lines)
            Padding(
              key: ObjectKey(line),
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: Row(
                children: [
                  Expanded(
                    child: NestTextField(
                      label: NannyCopy.checklists,
                      hint: NannyCopy.checklistItemHint,
                      controller: line.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          NannyLimits.routineLabel,
                        ),
                      ],
                    ),
                  ),
                  NestIconButton(
                    icon: Icons.delete_outline,
                    label: NannyCopy.removeItem,
                    variant: NestIconButtonVariant.plain,
                    onPressed: () => _remove(line),
                  ),
                ],
              ),
            ),
          if (_isFull)
            Text(
              NannyCopy.limitReached(NannyLimits.checklistItems),
              style: NestTheme.of(context).text.caption,
            )
          else
            NestButton(
              label: NannyCopy.addItem,
              icon: Icons.add,
              variant: NestButtonVariant.outline,
              onPressed: () => setState(() => _lines.add(_Line('', ''))),
            ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: NannyCopy.save,
            onPressed: () => Navigator.of(context).pop([
              for (final line in _lines)
                ChecklistItem(id: line.id, text: line.text.text),
            ]),
          ),
        ],
      ),
    );
  }
}
