import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';
import 'nest_pressable.dart';

class NestEditablePicture extends StatelessWidget {
  const NestEditablePicture({
    required this.child,
    required this.label,
    required this.onTap,
    this.icon = LucideIcons.pencil,
    this.pipSize = NestSize.avatarSmall,
    super.key,
  });

  final Widget child;
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final double pipSize;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: NestPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              PositionedDirectional(
                start: -NestSpace.xxs,
                bottom: -NestSpace.xxs,
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
                    dimension: pipSize,
                    child: Icon(
                      icon,
                      size: pipSize * 0.55,
                      color: c.onSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
