import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// "◷ 45 min   👥 Serves 6" under a recipe's name: how long, and for how many
/// — what a family decides on before anything else. A glyph and the words
/// both, so neither is the only signal (`FE-13`); it wraps rather than
/// clipping at a large text setting.
class RecipeMetaLine extends StatelessWidget {
  const RecipeMetaLine({
    required this.minutes,
    required this.servings,
    super.key,
  });

  final int minutes;
  final int servings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NestSpace.md,
      runSpacing: NestSpace.xxs,
      children: [
        if (minutes > 0)
          _Fact(icon: LucideIcons.clock, text: RecipeCopy.minutes(minutes)),
        _Fact(icon: LucideIcons.users, text: RecipeCopy.serves(servings)),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ink = nest.colors.inkSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: NestSize.iconBadge, color: ink),
        const SizedBox(width: NestSpace.xs),
        Flexible(
          child: Text(text, style: nest.text.caption.copyWith(color: ink)),
        ),
      ],
    );
  }
}
