import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';

/// The recipes while the catalogue is on its way: the search field, the
/// chips, tonight's photo and two cards, in the places they will take — so
/// nothing jumps when they arrive (`FE-08`). It scrolls rather than
/// overflowing in a short frame, and pulses unless motion is reduced.
class RecipeDiscoverySkeleton extends StatelessWidget {
  const RecipeDiscoverySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const NestSkeleton(height: NestSize.controlLarge),
        const SizedBox(height: NestSpace.md),
        Row(
          children: [
            for (var chip = 0; chip < 3; chip++) ...[
              if (chip > 0) const SizedBox(width: NestSpace.sm),
              const NestSkeleton(
                height: NestSize.controlSmall,
                width: NestSize.touchTarget * 2,
                radius: NestRadius.pill,
              ),
            ],
          ],
        ),
        const SizedBox(height: NestSpace.xxl),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: LayoutBuilder(
            builder: (context, constraints) => NestSkeleton(
              height: constraints.maxHeight,
              radius: NestRadius.xxl,
            ),
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        const NestSkeleton(
          height: NestSize.iconLarge,
          width: NestSize.placeTileMaxWidth,
        ),
        const SizedBox(height: NestSpace.sm),
        const NestSkeleton(height: NestSize.iconSmall),
      ],
    );
  }
}
