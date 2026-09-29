import 'package:flutter/material.dart';

import '../tokens/nest_member_palette.dart';
import '../tokens/nest_spacing.dart';
import '../tokens/nest_theme.dart';

/// A member's mark: their colour with their initial on it. The initial is
/// always drawn, so colour is never the only signal (`FE-13`); a ring marks
/// the member the screen is about.
class NestAvatar extends StatelessWidget {
  const NestAvatar({
    required this.name,
    required this.color,
    this.size = NestSize.avatarMedium,
    this.isHighlighted = false,
    super.key,
  });

  final String name;
  final MemberColor color;
  final double size;
  final bool isHighlighted;

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final swatch = nest.members.of(color);
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: swatch.fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: isHighlighted ? nest.colors.secondary : nest.colors.surface,
            width: NestStroke.focus,
          ),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Text(
              _initial,
              style: nest.text.bodyStrong.copyWith(
                color: swatch.onFill,
                fontSize: size * 0.42,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
