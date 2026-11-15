import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../model/avatar_creation.dart';
import 'creation_card.dart';

class CreationMenu extends StatelessWidget {
  const CreationMenu({
    required this.onPick,
    this.note,
    this.isSpent = false,
    this.offersPortrait = false,
    super.key,
  });

  final ValueChanged<CreationRecipe> onPick;
  final String? note;
  final bool isSpent;
  final bool offersPortrait;

  static const ownRecipes = [
    CreationRecipe.drawing,
    CreationRecipe.buddy,
    CreationRecipe.pet,
  ];

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final note = this.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AvatarCreationCopy.menuTitle, style: nest.text.title),
        const SizedBox(height: NestSpace.xs),
        Text(AvatarCreationCopy.menuBody, style: nest.text.bodySecondary),
        if (note != null) ...[
          const SizedBox(height: NestSpace.sm),
          Text(note, style: nest.text.label),
        ],
        for (final recipe in ownRecipes) ...[
          const SizedBox(height: NestSpace.md),
          CreationCard(
            key: ValueKey('create-${recipe.name}'),
            recipe: recipe,
            onTap: isSpent ? null : () => onPick(recipe),
          ),
        ],
        if (offersPortrait) ...[
          const SizedBox(height: NestSpace.xl),
          CreationCard(
            key: const ValueKey('create-portrait'),
            recipe: CreationRecipe.portrait,
            onTap: isSpent ? null : () => onPick(CreationRecipe.portrait),
          ),
        ],
      ],
    );
  }
}
