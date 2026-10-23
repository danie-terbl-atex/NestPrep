import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/allergen.dart';
import '../model/recipe.dart';

/// One of NestPrep's recipes, read in a sheet: what it is, how long it takes
/// and for how many, what it contains, the ingredients and the method.
/// Anywhere a recipe is named opens it the same way.
Future<void> showRecipeSheet(BuildContext context, Recipe recipe) =>
    showNestSheet<void>(
      context: context,
      title: recipe.name,
      builder: (_) => RecipeSheet(recipe: recipe),
    );

class RecipeSheet extends StatelessWidget {
  const RecipeSheet({required this.recipe, super.key});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final note = recipe.prepNote;
    return ListView(
      shrinkWrap: true,
      children: [
        if (recipe.summary.isNotEmpty) ...[
          Text(recipe.summary, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.md),
        ],
        Wrap(
          spacing: NestSpace.xs,
          runSpacing: NestSpace.xs,
          children: [
            NestTag(
              label: RecipeCopy.prepMinutes(recipe.prepMinutes),
              icon: LucideIcons.timer,
            ),
            NestTag(
              label: RecipeCopy.serves(recipe.servings),
              icon: LucideIcons.users,
            ),
            if (recipe.prepAhead)
              const NestTag(
                label: RecipeCopy.makeAhead,
                tone: NestTagTone.accent,
                icon: LucideIcons.calendarClock,
              ),
            for (final tag in recipe.dietTags)
              NestTag(label: RecipeCopy.dietTag(tag)),
          ],
        ),
        const SizedBox(height: NestSpace.md),
        Text(_contains(recipe.allergens), style: nest.text.caption),
        if (recipe.isAiDrafted) ...[
          const SizedBox(height: NestSpace.xs),
          Text(RecipeCopy.draftedNote, style: nest.text.caption),
        ],
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: RecipeCopy.ingredientsHeader),
        for (final line in recipe.ingredients)
          Padding(
            padding: const EdgeInsets.only(top: NestSpace.xs),
            child: Text(
              RecipeCopy.ingredient(
                name: line.name,
                quantity: line.quantity,
                unit: line.unit,
                note: line.note,
              ),
              style: nest.text.body,
            ),
          ),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: RecipeCopy.stepsHeader),
        for (final (index, step) in recipe.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(top: NestSpace.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  RecipeCopy.stepNumber(index + 1),
                  style: nest.text.bodyStrong,
                ),
                const SizedBox(width: NestSpace.sm),
                Expanded(child: Text(step, style: nest.text.body)),
              ],
            ),
          ),
        if (note != null) ...[
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: RecipeCopy.aheadHeader),
          const SizedBox(height: NestSpace.xs),
          Text(note, style: nest.text.body),
        ],
      ],
    );
  }

  /// Said in words, never only as tags (`FE-13`).
  static String _contains(Set<Allergen> allergens) => allergens.isEmpty
      ? RecipeCopy.containsNone
      : RecipeCopy.contains(
          [
            for (final allergen in Allergen.values)
              if (allergens.contains(allergen))
                FamilyCopy.allergenName(allergen).toLowerCase(),
          ].join(', '),
        );
}
