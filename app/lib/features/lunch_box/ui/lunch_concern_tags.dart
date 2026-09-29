import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_concern.dart';

/// What is wrong with something for this child, said in words and a tone
/// together — never colour alone (`FE-13`). Safety first, in danger; a
/// dislike after, in warning.
class LunchConcernTags extends StatelessWidget {
  const LunchConcernTags({required this.concerns, super.key});

  final List<LunchConcern> concerns;

  @override
  Widget build(BuildContext context) {
    if (concerns.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: NestSpace.xs,
      runSpacing: NestSpace.xs,
      children: [
        for (final concern in concerns)
          NestTag(
            label: concernLabel(concern),
            tone: concern.isUnsafe ? NestTagTone.danger : NestTagTone.warning,
            icon: concern.isUnsafe
                ? Icons.block_rounded
                : Icons.sentiment_dissatisfied_outlined,
          ),
      ],
    );
  }
}

/// A concern as a person reads it.
String concernLabel(LunchConcern concern) => switch (concern) {
  AllergenConcern(:final allergen) => LunchCopy.allergicTo(
    FamilyCopy.allergenName(allergen).toLowerCase(),
  ),
  NutRuleConcern(:final reasons) => LunchCopy.nutRule(reasons),
  DislikeConcern(:final dislike) => LunchCopy.doesNotLike(dislike),
};
