import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_motion.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_pressable.dart';

class NestPickTile extends StatelessWidget {
  const NestPickTile({
    required this.picture,
    required this.label,
    this.semanticLabel,
    this.isSelected = false,
    this.onTap,
    this.footer,
    super.key,
  });

  final Widget picture;
  final String label;
  final String? semanticLabel;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(NestRadius.lg),
      side: BorderSide(
        color: isSelected ? c.secondary : c.outline,
        width: isSelected ? NestStroke.focus : NestStroke.hairline,
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      selected: isSelected,
      label: semanticLabel ?? label,
      onTap: onTap,
      excludeSemantics: footer == null,
      child: NestPressable(
        enabled: onTap != null,
        child: AnimatedContainer(
          duration: NestMotion.of(context).quick,
          decoration: ShapeDecoration(
            color: isSelected ? c.secondarySoft : c.surface,
            shape: shape,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(NestSpace.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(child: picture),
                            if (isSelected)
                              PositionedDirectional(
                                top: 0,
                                end: 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: c.secondary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: c.surface,
                                      width: NestStroke.focus,
                                    ),
                                  ),
                                  child: SizedBox.square(
                                    dimension: NestSize.iconLarge,
                                    child: Icon(
                                      LucideIcons.check,
                                      size: NestSize.iconBadge,
                                      color: c.onSecondary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: NestSpace.xs),
                    ExcludeSemantics(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: nest.text.label.copyWith(color: c.ink),
                      ),
                    ),
                    if (footer case final footer?) ...[
                      const SizedBox(height: NestSpace.xs),
                      footer,
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
