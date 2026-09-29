import 'package:flutter/material.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A pill chip: a filter, a segment, a tag. Selected is the tonal violet.
class NestChip extends StatelessWidget {
  const NestChip({
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.trailingIcon,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// After the label — the cross on a chip that removes itself when tapped.
  final IconData? trailingIcon;

  /// What a screen reader says in place of [label], when tapping does
  /// something the label alone would not tell a listener: "Remove pasta"
  /// rather than "pasta" (`FE-13`).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final foreground = isSelected ? c.secondaryInk : c.inkSecondary;
    // Its own node: a chip beside a name or a heading must not merge into
    // them, or a screen reader announces the heading as the button and a tap
    // anywhere on it toggles the chip (`FE-13`).
    return Semantics(
      container: true,
      button: onTap != null,
      selected: isSelected,
      label: semanticLabel ?? label,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: NestMotion.of(context).quick,
        decoration: ShapeDecoration(
          color: isSelected ? c.secondarySoft : c.surface,
          shape: StadiumBorder(
            side: BorderSide(color: isSelected ? c.secondary : c.outline),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: NestSize.controlSmall,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: NestSpace.lg),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: NestSize.iconSmall, color: foreground),
                      const SizedBox(width: NestSpace.sm),
                    ],
                    // A chip is often given a fixed width by its parent, and its
                    // label grows with the platform's text setting — so the
                    // label yields rather than overflowing (`FE-13`).
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: nest.text.label.copyWith(color: foreground),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: NestSpace.xs),
                      Icon(
                        trailingIcon,
                        size: NestSize.iconSmall,
                        color: foreground,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
