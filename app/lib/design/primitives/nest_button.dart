import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

enum NestButtonVariant { primary, tonal, outline, ghost, danger }

enum NestButtonSize { small, medium, large }

/// The one text button of the app. Pill-shaped; variant and size are enums so
/// the look of every button changes in this file alone (`FE-03`). Loading
/// disables the press and keeps the width, so a form cannot double-submit.
class NestButton extends StatelessWidget {
  const NestButton({
    required this.label,
    required this.onPressed,
    this.variant = NestButtonVariant.primary,
    this.size = NestButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final NestButtonVariant variant;
  final NestButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final look = _isEnabled
        ? _NestButtonLook.resolve(nest, variant)
        : _NestButtonLook.disabled(nest, variant);
    final height = switch (size) {
      NestButtonSize.small => NestSize.controlSmall,
      NestButtonSize.medium => NestSize.controlMedium,
      NestButtonSize.large => NestSize.controlLarge,
    };
    final foreground = look.foreground;
    final child = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox.square(
            dimension: NestSize.iconSmall,
            child: CircularProgressIndicator(
              strokeWidth: NestStroke.focus,
              color: foreground,
            ),
          )
        else if (icon != null)
          Icon(icon, size: NestSize.iconMedium, color: foreground),
        if (isLoading || icon != null) const SizedBox(width: NestSpace.sm),
        // The label grows with the platform's text setting while the button's
        // width does not, so the label yields rather than overflowing
        // (`FE-13`). Semantics carries the whole label either way.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: nest.text.button.copyWith(color: foreground),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: label,
      child: Material(
        color: look.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NestRadius.pill),
          side: look.border ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isEnabled ? onPressed : null,
          splashColor: look.pressed,
          highlightColor: look.pressed,
          child: SizedBox(
            height: height,
            width: isExpanded ? double.infinity : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NestSpace.xxl),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _NestButtonLook {
  const _NestButtonLook({
    required this.background,
    required this.foreground,
    required this.pressed,
    this.border,
  });

  final Color background;
  final Color foreground;
  final Color pressed;
  final BorderSide? border;

  /// What a button looks like when it cannot be pressed.
  ///
  /// This is a *pair*, not a fade. Fading the whole button moved its fill and
  /// its label toward the page together and left the label at 1.17:1 on the
  /// sign-in screen — violet on grey, and unreadable (`FE-13`). A filled button
  /// says "disabled" by losing its colour instead; the flat variants keep their
  /// surface and mute only the ink. Every pair below is proven AA in
  /// `test/design/tokens/nest_contrast_test.dart`.
  static _NestButtonLook disabled(NestTheme nest, NestButtonVariant variant) {
    final c = nest.colors;
    return switch (variant) {
      NestButtonVariant.primary ||
      NestButtonVariant.tonal ||
      NestButtonVariant.danger => _NestButtonLook(
        background: c.outlineStrong,
        foreground: c.ink,
        pressed: c.outlineStrong,
      ),
      NestButtonVariant.outline => _NestButtonLook(
        background: c.surface,
        foreground: c.inkTertiary,
        pressed: c.surface,
        border: BorderSide(color: c.outline),
      ),
      NestButtonVariant.ghost => _NestButtonLook(
        background: Colors.transparent,
        foreground: c.inkTertiary,
        pressed: Colors.transparent,
      ),
    };
  }

  static _NestButtonLook resolve(NestTheme nest, NestButtonVariant variant) {
    final c = nest.colors;
    return switch (variant) {
      NestButtonVariant.primary => _NestButtonLook(
        background: c.accent,
        foreground: c.onAccent,
        pressed: c.accentPressed,
      ),
      NestButtonVariant.tonal => _NestButtonLook(
        background: c.accentSoft,
        foreground: c.accentInk,
        pressed: c.surfaceTint,
      ),
      NestButtonVariant.outline => _NestButtonLook(
        background: c.surface,
        foreground: c.ink,
        pressed: c.surfaceTint,
        border: BorderSide(color: c.outlineStrong),
      ),
      NestButtonVariant.ghost => _NestButtonLook(
        background: Colors.transparent,
        foreground: c.accentInk,
        pressed: c.accentSoft,
      ),
      NestButtonVariant.danger => _NestButtonLook(
        background: c.danger,
        foreground: c.onDanger,
        pressed: c.dangerSoft,
      ),
    };
  }
}
