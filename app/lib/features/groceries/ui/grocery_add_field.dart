import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// Adds an item without leaving the list. Submitting clears the field and keeps
/// focus, because somebody standing in a kitchen types four things in a row.
///
/// The screen owns [controller] and [focusNode] when something else — the
/// shop's products as you type — also reads or clears what is typed.
/// [leading] sits before the field: the shop it matches at.
class GroceryAddField extends StatefulWidget {
  const GroceryAddField({
    required this.onSubmit,
    this.controller,
    this.focusNode,
    this.leading,
    super.key,
  });

  final Future<void> Function(String name, {String? quantity}) onSubmit;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Widget? leading;

  @override
  State<GroceryAddField> createState() => _GroceryAddFieldState();
}

class _GroceryAddFieldState extends State<GroceryAddField> {
  TextEditingController? _ownName;
  FocusNode? _ownFocus;

  TextEditingController get _name =>
      widget.controller ?? (_ownName ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void dispose() {
    _ownName?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leading = widget.leading;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (leading != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.xxs),
            child: leading,
          ),
          const SizedBox(width: NestSpace.sm),
        ],
        Expanded(
          child: NestTextField(
            label: AppCopy.groceriesAdd,
            hint: AppCopy.groceriesAddHint,
            controller: _name,
            focusNode: _focus,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: NestSpace.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.xxs),
          child: ListenableBuilder(
            listenable: _name,
            builder: (context, _) => NestIconButton(
              icon: LucideIcons.plus,
              label: AppCopy.groceriesAdd,
              variant: NestIconButtonVariant.accent,
              onPressed: _name.text.trim().isNotEmpty ? _submit : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _name.text;
    if (name.trim().isEmpty) return;
    _name.clear();
    _focus.requestFocus();
    await widget.onSubmit(name);
  }
}
