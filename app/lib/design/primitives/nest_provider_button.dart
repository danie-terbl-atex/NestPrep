import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_pressable.dart';
import 'nest_provider_mark.dart';

/// A round sign-in button that is only the provider's mark: a hairline circle
/// on the page, the size of a large button so it sits level with the text
/// buttons above it. The mark is the picture; [label] is the words, read
/// aloud and shown as a tooltip (`FE-13`). Loading swaps the mark for a
/// spinner and disables the press, so a sign-in cannot be asked twice.
class NestProviderButton extends StatelessWidget {
  const NestProviderButton({
    required this.provider,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final NestProvider provider;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return Semantics(
      container: true,
      button: true,
      label: label,
      enabled: _isEnabled,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: NestPressable(
          enabled: _isEnabled,
          child: Material(
            color: c.surface,
            shape: CircleBorder(
              side: BorderSide(color: _isEnabled ? c.outlineStrong : c.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isEnabled ? onPressed : null,
              splashColor: c.surfaceTint,
              highlightColor: c.surfaceTint,
              child: SizedBox.square(
                dimension: NestSize.controlLarge,
                child: Center(
                  child: isLoading
                      ? SizedBox.square(
                          dimension: NestSize.iconSmall,
                          child: CircularProgressIndicator(
                            strokeWidth: NestStroke.focus,
                            color: c.ink,
                          ),
                        )
                      : Opacity(
                          opacity: _isEnabled ? 1 : 0.4,
                          child: NestProviderMark(provider: provider),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
