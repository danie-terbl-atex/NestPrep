import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe_photo.dart';

/// Whose photo this is and under what licence, or that it is an
/// illustration NestPrep made (recipes ADR-0003 §4) — a quiet line at the
/// foot of the recipe, because an open licence asks for the credit and a
/// generated picture must never pass as a photo of the cook's result.
class RecipePhotoCredit extends StatelessWidget {
  const RecipePhotoCredit({required this.photo, super.key});

  final RecipePhoto photo;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final credit = photo.credit;
    final source = photo.sourceUrl;
    final words = photo.isGenerated || credit == null
        ? RecipeCopy.photoIllustrative
        : RecipeCopy.photoCredit(credit, photo.licence);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: NestSpace.xxs),
          child: Icon(
            LucideIcons.camera,
            size: NestSize.iconBadge,
            color: nest.colors.inkTertiary,
          ),
        ),
        const SizedBox(width: NestSpace.sm),
        Expanded(
          child: Text(
            source == null || photo.isGenerated
                ? words
                : RecipeCopy.withSource(words, source),
            style: nest.text.caption,
          ),
        ),
      ],
    );
  }
}
