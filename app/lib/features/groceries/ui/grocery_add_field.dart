import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// Adds an item without leaving the list. Submitting clears the field and keeps
/// focus, because somebody standing in a kitchen types four things in a row.
class GroceryAddField extends StatefulWidget {
  const GroceryAddField({required this.onSubmit, super.key});

  final Future<void> Function(String name, {String? quantity}) onSubmit;

  @override
  State<GroceryAddField> createState() => _GroceryAddFieldState();
}

class _GroceryAddFieldState extends State<GroceryAddField> {
  final _name = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _name.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _name.text.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: NestTextField(
            label: AppCopy.groceriesAdd,
            hint: AppCopy.groceriesAddHint,
            controller: _name,
            focusNode: _focus,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: NestSpace.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.xxs),
          child: NestIconButton(
            icon: Icons.add,
            label: AppCopy.groceriesAdd,
            variant: NestIconButtonVariant.accent,
            onPressed: canSubmit ? _submit : null,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _name.text;
    if (name.trim().isEmpty) return;
    _name.clear();
    setState(() {});
    _focus.requestFocus();
    await widget.onSubmit(name);
  }
}
