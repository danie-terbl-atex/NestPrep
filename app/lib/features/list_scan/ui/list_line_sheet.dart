import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/list_scan_line.dart';

sealed class ListLineEdit {
  const ListLineEdit();
}

final class ListLineChanged extends ListLineEdit {
  const ListLineChanged({required this.name, required this.quantity});

  final String name;
  final String quantity;
}

final class ListLineLeftOff extends ListLineEdit {
  const ListLineLeftOff();
}

/// The name and how much of one line, in the grocery list's own words for
/// both — or leaving it off. Null when the sheet was closed.
Future<ListLineEdit?> showListLineSheet({
  required BuildContext context,
  required ListScanLine line,
}) => showNestSheet<ListLineEdit>(
  context: context,
  title: ListScanCopy.editTitle,
  builder: (_) => _ListLineSheetBody(line: line),
);

class _ListLineSheetBody extends StatefulWidget {
  const _ListLineSheetBody({required this.line});

  final ListScanLine line;

  @override
  State<_ListLineSheetBody> createState() => _ListLineSheetBodyState();
}

class _ListLineSheetBodyState extends State<_ListLineSheetBody> {
  late final _name = TextEditingController(text: widget.line.name);
  late final _quantity = TextEditingController(
    text: widget.line.quantity ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _name.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestTextField(
          label: ListScanCopy.nameLabel,
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.lg),
        NestTextField(
          label: AppCopy.groceriesQuantityHint,
          controller: _quantity,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (canSave) _save();
          },
        ),
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          key: const ValueKey('list-line-save'),
          label: ListScanCopy.save,
          onPressed: canSave ? _save : null,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: ListScanCopy.remove,
          variant: NestButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(const ListLineLeftOff()),
        ),
      ],
    );
  }

  void _save() =>
      Navigator.of(context)
          .pop(ListLineChanged(name: _name.text, quantity: _quantity.text));
}
