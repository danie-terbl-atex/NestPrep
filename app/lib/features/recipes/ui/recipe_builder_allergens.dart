import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/allergen.dart';
import '../state/recipe_builder_controller.dart';

class RecipeBuilderAllergens extends StatelessWidget {
  const RecipeBuilderAllergens({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeBuilderController>();
    final derived = controller.derivedAllergens;
    final added = controller.form.alsoContains;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OwnRecipeCopy.allergensBuilderNote, style: nest.text.caption),
        const SizedBox(height: NestSpace.md),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final allergen in Allergen.values)
              NestChip(
                key: ValueKey('recipe-allergen-${allergen.name}'),
                label: FamilyCopy.allergenName(allergen),
                icon: derived.contains(allergen)
                    ? LucideIcons.lock
                    : added.contains(allergen)
                    ? LucideIcons.check
                    : LucideIcons.plus,
                isSelected:
                    derived.contains(allergen) || added.contains(allergen),
                semanticLabel: derived.contains(allergen)
                    ? OwnRecipeCopy.allergenFound(allergen)
                    : added.contains(allergen)
                    ? OwnRecipeCopy.allergenAdded(allergen)
                    : OwnRecipeCopy.allergenToAdd(allergen),
                onTap: derived.contains(allergen)
                    ? null
                    : () => controller.update(
                        (form) => form.withAllergenToggled(allergen),
                      ),
              ),
          ],
        ),
      ],
    );
  }
}
