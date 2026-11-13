import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';

class RecipeBuilderField extends StatefulWidget {
  const RecipeBuilderField({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.limit,
    this.maxLines = 1,
    this.isNumber = false,
    super.key,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  final String? hint;
  final String? errorText;
  final int? limit;
  final int maxLines;
  final bool isNumber;

  @override
  State<RecipeBuilderField> createState() => _RecipeBuilderFieldState();
}

class _RecipeBuilderFieldState extends State<RecipeBuilderField> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final limit = widget.limit;
    return NestTextField(
      label: widget.label,
      hint: widget.hint,
      controller: _text,
      errorText: widget.errorText,
      maxLines: widget.maxLines,
      keyboardType: widget.isNumber ? TextInputType.number : null,
      inputFormatters: [
        if (widget.isNumber) FilteringTextInputFormatter.digitsOnly,
        if (limit != null) LengthLimitingTextInputFormatter(limit),
      ],
      onChanged: widget.onChanged,
    );
  }
}
