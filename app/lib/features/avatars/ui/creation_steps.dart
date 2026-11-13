import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/avatar_creation_copy.dart';
import '../model/avatar_creation.dart';

class CreationSteps extends StatelessWidget {
  const CreationSteps({required this.recipe, required this.reached, super.key});

  final CreationRecipe recipe;
  final int reached;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final steps = [
      AvatarCreationCopy.stepSending,
      AvatarCreationCopy.stepChecking(recipe),
      AvatarCreationCopy.stepDrawing,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
            child: Row(
              children: [
                Icon(
                  index < reached
                      ? LucideIcons.circleCheck
                      : index == reached
                      ? LucideIcons.circleDot
                      : LucideIcons.circle,
                  size: NestSize.iconMedium,
                  color: index < reached
                      ? c.success
                      : index == reached
                      ? c.ink
                      : c.inkTertiary,
                ),
                const SizedBox(width: NestSpace.md),
                Expanded(
                  child: Text(
                    step,
                    style: index == reached
                        ? nest.text.bodyStrong
                        : nest.text.bodySecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
