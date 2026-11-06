import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../shared/copy/app_copy.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_icon_button.dart';

/// The text input. Rounded, hairline, with the label above and the error
/// below in the danger ink; validation happens in the form, not here (`FE-10`).
///
/// An [obscureText] field always carries an eye that shows what was typed, so
/// a password is never typed blind (accounts ADR-0013).
class NestTextField extends StatefulWidget {
  const NestTextField({
    required this.label,
    this.controller,
    this.focusNode,
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
    this.autofillHints,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
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

  /// What the platform's password manager may fill here and offer to save;
  /// saving needs the fields inside an `AutofillGroup` (accounts ADR-0013).
  final Iterable<String>? autofillHints;

  @override
  State<NestTextField> createState() => _NestTextFieldState();
}

class _NestTextFieldState extends State<NestTextField> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: nest.text.label.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          obscureText: widget.obscureText && !_revealed,
          autocorrect: !widget.obscureText,
          enableSuggestions: !widget.obscureText,
          autofillHints: widget.autofillHints,
          maxLines: widget.maxLines,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: nest.text.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            helperText: widget.helperText,
            errorStyle: nest.text.caption.copyWith(color: c.danger),
            helperStyle: nest.text.caption,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(
                    widget.prefixIcon,
                    size: NestSize.iconMedium,
                    color: c.inkTertiary,
                  ),
            suffixIcon: widget.obscureText
                ? NestIconButton(
                    icon: _revealed ? LucideIcons.eyeOff : LucideIcons.eye,
                    label: _revealed
                        ? AppCopy.hidePassword
                        : AppCopy.showPassword,
                    variant: NestIconButtonVariant.plain,
                    onPressed: widget.enabled
                        ? () => setState(() => _revealed = !_revealed)
                        : null,
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}
