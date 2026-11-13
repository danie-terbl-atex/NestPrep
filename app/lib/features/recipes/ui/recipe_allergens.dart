import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/allergen.dart';

/// What a recipe contains of the nine allergens a family records, as tags a
/// parent scans — each with a warning glyph and its name — and none at all
/// said in words too, never by an absence (`FE-13`). The codes are the
/// catalogue's own (recipes ADR-0001 §5); this only shows them.
class RecipeAllergens extends StatelessWidget {
  const RecipeAllergens({
    required this.allergens,
    this.isOwn = false,
    super.key,
  });

  final Set<Allergen> allergens;

  /// The words an own recipe is read from may not be English, so finding
  /// nothing there is never an all-clear (recipes ADR-0007 §5).
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    if (isOwn) return _OwnRecipeAllergens(names: _names);
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
    return _AllergenTags(names: _names);
  }

  List<String> get _names => [
    for (final allergen in Allergen.values)
      if (allergens.contains(allergen)) FamilyCopy.allergenName(allergen),
  ];
}

class _AllergenTags extends StatelessWidget {
  const _AllergenTags({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
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

class _OwnRecipeAllergens extends StatelessWidget {
  const _OwnRecipeAllergens({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (names.isNotEmpty) ...[
          _AllergenTags(names: names),
          const SizedBox(height: NestSpace.sm),
        ],
        Text(
          names.isEmpty
              ? OwnRecipeCopy.allergensNoneFound
              : OwnRecipeCopy.allergensFound,
          style: nest.text.caption,
        ),
      ],
    );
  }
}
