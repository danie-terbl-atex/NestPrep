import 'package:flutter/material.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

enum NestIconButtonVariant { glass, accent, plain }

/// The round icon button of the header row and the action corners: a hairline
/// circle on the glass surface, or a solid accent disc. Always the touch-target
/// floor, and always labelled (`FE-13`).
class NestIconButton extends StatelessWidget {
  const NestIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = NestIconButtonVariant.glass,
    this.badge = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final NestIconButtonVariant variant;

  /// A small accent dot, for "something new" without a count.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final (background, foreground, border) = switch (variant) {
      NestIconButtonVariant.glass => (c.surfaceGlass, c.ink, c.outline),
      NestIconButtonVariant.accent => (c.accent, c.onAccent, c.accent),
      NestIconButtonVariant.plain => (
        Colors.transparent,
        c.ink,
        Colors.transparent,
      ),
    };
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: Tooltip(
        message: label,
        child: Material(
          color: background,
          shape: CircleBorder(side: BorderSide(color: border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: NestSize.touchTarget,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: NestSize.iconMedium, color: foreground),
                  if (badge)
                    Positioned(
                      top: NestSpace.md,
                      right: NestSpace.md,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: background),
                        ),
                        child: const SizedBox.square(dimension: NestSpace.sm),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
