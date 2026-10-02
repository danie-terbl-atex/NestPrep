import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/dietary_flag.dart';
import 'family_section_card.dart';
import 'family_section_empty.dart';
import 'labelled_tags.dart';

/// What a person likes, what they will not eat, and how they eat — the three
/// things a lunch is planned around after the allergies.
class FoodSection extends StatelessWidget {
  const FoodSection({
    required this.likes,
    required this.dislikes,
    required this.diet,
    required this.onEdit,
    super.key,
  });

  final List<String> likes;
  final List<String> dislikes;
  final Set<DietaryFlag> diet;

  /// Null when the viewer may not change this profile.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final isEmpty = likes.isEmpty && dislikes.isEmpty && diet.isEmpty;
    return FamilySectionCard(
      icon: LucideIcons.utensils,
      tint: NestTileTint.basil,
      title: FamilyCopy.sectionFood,
      actionLabel: FamilyCopy.editSection(FamilyCopy.sectionFood),
      onAction: onEdit,
      child: isEmpty
          ? const FamilySectionEmpty(message: FamilyCopy.noFood)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (diet.isNotEmpty)
                  LabelledTags(
                    label: FamilyCopy.diet,
                    tags: [
                      for (final flag in DietaryFlag.values)
                        if (diet.contains(flag))
                          NestTag(
                            label: FamilyCopy.dietName(flag),
                            tone: NestTagTone.accent,
                          ),
                    ],
                  ),
                if (likes.isNotEmpty)
                  LabelledTags(
                    label: FamilyCopy.likes,
                    tags: [
                      for (final like in likes)
                        NestTag(
                          label: like,
                          tone: NestTagTone.success,
                          icon: LucideIcons.heart,
                        ),
                    ],
                  ),
                if (dislikes.isNotEmpty)
                  LabelledTags(
                    label: FamilyCopy.dislikes,
                    tags: [
                      for (final dislike in dislikes)
                        NestTag(label: dislike, icon: LucideIcons.circleMinus),
                    ],
                  ),
              ],
            ),
    );
  }
}
