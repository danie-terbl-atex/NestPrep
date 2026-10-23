import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/allergen.dart';

/// What a recipe contains of the nine allergens a family records, as tags a
/// parent scans — each with a warning glyph and its name — and none at all
/// said in words too, never by an absence (`FE-13`). The codes are the
/// catalogue's own (recipes ADR-0001 §5); this only shows them.
class RecipeAllergens extends StatelessWidget {
  const RecipeAllergens({required this.allergens, super.key});

  final Set<Allergen> allergens;

  @override
  Widget build(BuildContext context) {
    if (allergens.isEmpty) {
      return const Align(
        alignment: AlignmentDirectional.centerStart,
        child: NestTag(
          label: RecipeCopy.containsNone,
          tone: NestTagTone.success,
          icon: LucideIcons.shieldCheck,
        ),
      );
    }
    final names = [
      for (final allergen in Allergen.values)
        if (allergens.contains(allergen)) FamilyCopy.allergenName(allergen),
    ];
    return Semantics(
      container: true,
      label: RecipeCopy.contains(names.join(', ').toLowerCase()),
      excludeSemantics: true,
      child: Wrap(
        spacing: NestSpace.xs,
        runSpacing: NestSpace.xs,
        children: [
          for (final name in names)
            NestTag(
              label: name,
              tone: NestTagTone.warning,
              icon: LucideIcons.triangleAlert,
            ),
        ],
      ),
    );
  }
}
