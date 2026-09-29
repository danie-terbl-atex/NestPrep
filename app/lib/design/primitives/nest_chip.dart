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
    this.semanticLabel,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  /// What a screen reader says when the tap does something the label alone
  /// does not — "Remove ID" for a chip that reads "ID".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final foreground = isSelected ? c.accentInk : c.inkSecondary;
    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: semanticLabel ?? label,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: NestMotion.of(context).quick,
        decoration: ShapeDecoration(
          color: isSelected ? c.accentSoft : c.surface,
          shape: StadiumBorder(
            side: BorderSide(color: isSelected ? c.accentSoft : c.outline),
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
