import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/food_rules.dart';
import '../../family_profiles/ui/family_section_card.dart';
import '../../family_profiles/ui/family_section_empty.dart';

/// What the child likes and will not eat — family profiles' words, read here
/// and changed there, so the lunch planner and the carer agree (nanny-hub
/// ADR-0003). Nothing is shown for a viewer who may not read the profile; the
/// allergy card above has already said why.
class LikesSection extends StatelessWidget {
  const LikesSection({required this.food, super.key});

  final AsyncState<FoodRules>? food;

  @override
  Widget build(BuildContext context) {
    final rules = switch (food) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (rules == null) return const SizedBox.shrink();
    return FamilySectionCard(
      icon: Icons.favorite_border,
      tint: NestTileTint.mint,
      title: NannyCopy.likesAndDislikes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Words(label: NannyCopy.likes, words: rules.likes),
          const SizedBox(height: NestSpace.md),
          _Words(label: NannyCopy.dislikes, words: rules.dislikes),
        ],
      ),
    );
  }
}

class _Words extends StatelessWidget {
  const _Words({required this.label, required this.words});

  final String label;
  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.xs),
        if (words.isEmpty)
          const FamilySectionEmpty(message: NannyCopy.noLikes)
        else
          Wrap(
            spacing: NestSpace.xs,
            runSpacing: NestSpace.xs,
            children: [for (final word in words) NestTag(label: word)],
          ),
      ],
    );
  }
}
