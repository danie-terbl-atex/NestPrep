import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe_scale.dart';
import 'people_glyph_row.dart';

/// *Cooking for − 4 people +* (recipes ADR-0003 §5): the number always in
/// figures, a row of people that fill as somebody is added, how far that
/// scales the recipe (×2/3), and one tap back to the recipe as written.
///
/// A screen reader hears "Cooking for 4 people", again each time it changes,
/// and the two buttons by what they do (`FE-13`). It shows [scale] and
/// reports taps; the arithmetic is the controller's (`FE-04`).
class PeopleScaler extends StatelessWidget {
  const PeopleScaler({
    required this.scale,
    required this.onAdd,
    required this.onRemove,
    required this.onReset,
    super.key,
  });

  final RecipeScale scale;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final people = scale.people;
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: RecipeCopy.cookingForLabel(people),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const NestEyebrow(RecipeCopy.cookingFor),
                        const SizedBox(height: NestSpace.xs),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: NestSpace.sm,
                          children: [
                            Text('$people', style: nest.text.figure),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: NestSpace.xs,
                              ),
                              child: Text(
                                RecipeCopy.people(people),
                                style: nest.text.title,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              NestIconButton(
                icon: LucideIcons.minus,
                label: RecipeCopy.removePerson,
                onPressed: scale.canRemove ? onRemove : null,
              ),
              const SizedBox(width: NestSpace.sm),
              NestIconButton(
                icon: LucideIcons.plus,
                label: RecipeCopy.addPerson,
                variant: NestIconButtonVariant.accent,
                onPressed: scale.canAdd ? onAdd : null,
              ),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          PeopleGlyphRow(people: people, servings: scale.servings),
          const SizedBox(height: NestSpace.lg),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              Semantics(
                container: true,
                label: scale.isAsWritten
                    ? RecipeCopy.asWritten
                    : RecipeCopy.scaleLabel(scale.factorText),
                excludeSemantics: true,
                child: NestTag(
                  label: scale.isAsWritten
                      ? RecipeCopy.asWritten
                      : RecipeCopy.scaleChip(scale.factorText),
                  tone: NestTagTone.accent,
                  icon: LucideIcons.scale,
                  isFigure: true,
                ),
              ),
              if (!scale.isAsWritten)
                NestChip(
                  label: RecipeCopy.resetTo(scale.servings),
                  icon: LucideIcons.rotateCcw,
                  onTap: onReset,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
