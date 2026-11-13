import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// With [canAddMore] it stays open for the next one until that says no.
Future<void> showRecipeTextSheet({
  required BuildContext context,
  required String title,
  required String label,
  required String hint,
  required String submitLabel,
  required int limit,
  required ValueChanged<String> onSubmit,
  String initial = '',
  int maxLines = 1,
  bool Function()? canAddMore,
}) => showNestSheet<void>(
  context: context,
  title: title,
  builder: (_) => _RecipeTextForm(
    label: label,
    hint: hint,
    submitLabel: submitLabel,
    limit: limit,
    initial: initial,
    maxLines: maxLines,
    canAddMore: canAddMore,
    onSubmit: onSubmit,
  ),
);

class _RecipeTextForm extends StatefulWidget {
  const _RecipeTextForm({
    required this.label,
    required this.hint,
    required this.submitLabel,
    required this.limit,
    required this.initial,
    required this.maxLines,
    required this.canAddMore,
    required this.onSubmit,
  });

  final String label;
  final String hint;
  final String submitLabel;
  final int limit;
  final String initial;
  final int maxLines;
  final bool Function()? canAddMore;
  final ValueChanged<String> onSubmit;

  @override
  State<_RecipeTextForm> createState() => _RecipeTextFormState();
}

class _RecipeTextFormState extends State<_RecipeTextForm> {
  late final _text = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    if (widget.canAddMore?.call() ?? false) {
      _text.clear();
      setState(() {});
      _focus.requestFocus();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final addsMore = widget.canAddMore != null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            key: const ValueKey('recipe-text-field'),
            label: widget.label,
            hint: widget.hint,
            controller: _text,
            focusNode: _focus,
            autofocus: true,
            maxLines: widget.maxLines,
            inputFormatters: [LengthLimitingTextInputFormatter(widget.limit)],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            key: const ValueKey('recipe-text-submit'),
            label: widget.submitLabel,
            variant: addsMore
                ? NestButtonVariant.tonal
                : NestButtonVariant.primary,
            onPressed: _text.text.trim().isEmpty ? null : _submit,
          ),
          if (addsMore) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              key: const ValueKey('recipe-text-done'),
              label: OwnRecipeCopy.done,
              variant: NestButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}
