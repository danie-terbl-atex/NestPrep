import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../model/avatar_creation.dart';
import '../model/avatar_studio.dart';
import '../state/creation_step.dart';
import 'creation_egg.dart';
import 'creation_steps.dart';

class CreationHatching extends StatelessWidget {
  const CreationHatching({required this.studio, required this.step, super.key});

  final AvatarStudio studio;
  final CreationStep step;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final (recipe, reached) = switch (step) {
      CreationSending(:final recipe) => (recipe, 0),
      CreationWaiting(:final recipe, :final isDrawing) => (
        recipe,
        isDrawing ? 2 : 1,
      ),
      _ => (CreationRecipe.buddy, 0),
    };
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: NestEggWobble(
              child: CreationEgg(studio: studio, size: NestSize.avatarHero),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          Row(
            children: [
              const NestTwig(
                pose: NestTwigPose.thinking,
                semanticsLabel: AvatarCreationCopy.aiAtWork,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    AvatarCreationCopy.hatching(recipe),
                    style: nest.text.title,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          Text(AvatarCreationCopy.waitBody, style: nest.text.bodySecondary),
          const SizedBox(height: NestSpace.md),
          CreationSteps(recipe: recipe, reached: reached),
        ],
      ),
    );
  }
}
