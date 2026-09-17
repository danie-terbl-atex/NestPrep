import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// The text input. Rounded, hairline, with the label above and the error
/// below in the danger ink; validation happens in the form, not here (`FE-10`).
class NestTextField extends StatelessWidget {
  const NestTextField({
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.sentences,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  /// Applied as the person types. Anything that changes what they typed has to
  /// be visible while they type it, never on submit (`FE-10`).
  final List<TextInputFormatter>? inputFormatters;

  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: nest.text.label.copyWith(color: c.inkSecondary)),
        const SizedBox(height: NestSpace.sm),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          maxLines: maxLines,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: nest.text.body,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            helperText: helperText,
            errorStyle: nest.text.caption.copyWith(color: c.danger),
            helperStyle: nest.text.caption,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(
                    prefixIcon,
                    size: NestSize.iconMedium,
                    color: c.inkTertiary,
                  ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
