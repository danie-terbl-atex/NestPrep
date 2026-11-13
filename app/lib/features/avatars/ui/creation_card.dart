import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../model/avatar_creation.dart';

class CreationCard extends StatelessWidget {
  const CreationCard({
    required this.recipe,
    required this.onTap,
    this.tag,
    super.key,
  });

  final CreationRecipe recipe;
  final VoidCallback? onTap;
  final String? tag;

  static IconData iconOf(CreationRecipe recipe) => switch (recipe) {
    CreationRecipe.drawing => LucideIcons.palette,
    CreationRecipe.buddy => LucideIcons.wandSparkles,
    CreationRecipe.pet => LucideIcons.pawPrint,
    CreationRecipe.portrait => LucideIcons.frame,
  };

  static NestTileTint tintOf(CreationRecipe recipe) => switch (recipe) {
    CreationRecipe.drawing => NestTileTint.butter,
    CreationRecipe.buddy => NestTileTint.lilac,
    CreationRecipe.pet => NestTileTint.basil,
    CreationRecipe.portrait => NestTileTint.guava,
  };

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final label = tag;
    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      label:
          '${AvatarCreationCopy.recipeTitle(recipe)}. '
          '${AvatarCreationCopy.recipeBody(recipe)}'
          '${label == null ? '' : '. $label'}',
      excludeSemantics: true,
      child: NestCard(
        onTap: onTap,
        child: Row(
          children: [
            NestIconTile(
              icon: iconOf(recipe),
              tint: tintOf(recipe),
              size: NestSize.controlHuge,
            ),
            const SizedBox(width: NestSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AvatarCreationCopy.recipeTitle(recipe),
                    style: nest.text.cardTitle,
                  ),
                  const SizedBox(height: NestSpace.xxs),
                  Text(
                    AvatarCreationCopy.recipeBody(recipe),
                    style: nest.text.bodySecondary,
                  ),
                  if (label != null) ...[
                    const SizedBox(height: NestSpace.sm),
                    NestTag(
                      label: label,
                      tone: NestTagTone.accent,
                      icon: LucideIcons.sparkles,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: NestSpace.sm),
            Icon(
              LucideIcons.chevronRight,
              color: nest.colors.inkTertiary,
              size: NestSize.iconMedium,
            ),
          ],
        ),
      ),
    );
  }
}
