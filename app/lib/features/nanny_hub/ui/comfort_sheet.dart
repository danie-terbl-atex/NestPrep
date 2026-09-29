import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/ui/chip_list_editor.dart';

/// Edits a child's comfort items as chips — the same editor family profiles
/// uses for likes (`ENG-01`), which trims and de-duplicates as it adds and
/// stops at the limit the rules keep. Null when closed without saving.
Future<List<String>?> showComfortSheet({
  required BuildContext context,
  required List<String> items,
}) => showNestSheet<List<String>>(
  context: context,
  title: NannyCopy.editComfort,
  builder: (_) => _ComfortSheetBody(items: items),
);

class _ComfortSheetBody extends StatefulWidget {
  const _ComfortSheetBody({required this.items});

  final List<String> items;

  @override
  State<_ComfortSheetBody> createState() => _ComfortSheetBodyState();
}

class _ComfortSheetBodyState extends State<_ComfortSheetBody> {
  late List<String> _items = widget.items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ChipListEditor(
            label: NannyCopy.comfort,
            hint: NannyCopy.comfortHint,
            values: _items,
            onChanged: (items) => setState(() => _items = items),
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: NannyCopy.save,
            onPressed: () => Navigator.of(context).pop(_items),
          ),
        ],
      ),
    );
  }
}
