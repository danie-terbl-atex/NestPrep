import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe.dart';
import 'recipe_meta_line.dart';
import 'recipe_picture.dart';

/// The recipes' lead: one dinner for tonight, large — the photo with an Oat
/// pill over its corner, then its name in the display face, what it is, and
/// how long and for how many. The same shape Today's lunch card has, so the
/// two read as one app (design-system ADR-0008).
class RecipeTonightCard extends StatelessWidget {
  const RecipeTonightCard({
    required this.recipe,
    required this.onOpen,
    super.key,
  });

  final Recipe recipe;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestEyebrow(RecipeCopy.tonightEyebrow),
        const SizedBox(height: NestSpace.sm),
        NestPhotoCard(
          photo: RecipePicture(path: recipe.photo?.hero),
          onTap: onOpen,
          actionLabel: RecipeCopy.tonightAction,
          actionIcon: LucideIcons.arrowUpRight,
          semanticsLabel: RecipeCopy.cardLabel(
            name: recipe.name,
            minutes: recipe.totalMinutes,
            servings: recipe.servings,
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        Text(recipe.name, style: nest.text.headline),
        if (recipe.summary.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xs),
          Text(recipe.summary, style: nest.text.bodySecondary),
        ],
        const SizedBox(height: NestSpace.sm),
        RecipeMetaLine(minutes: recipe.totalMinutes, servings: recipe.servings),
      ],
    );
  }
}
