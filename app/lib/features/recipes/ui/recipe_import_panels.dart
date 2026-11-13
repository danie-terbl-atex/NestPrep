import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../model/recipe_import_way.dart';
import '../state/recipe_import_controller.dart';

class RecipeImportWorkingPanel extends StatelessWidget {
  const RecipeImportWorkingPanel({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      liveRegion: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const NestTwig(pose: NestTwigPose.thinking),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: nest.text.title.copyWith(color: nest.colors.ink),
                    ),
                    Text(
                      body,
                      style: nest.text.body.copyWith(
                        color: nest.colors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          const Expanded(child: NestLoadingView(rows: 5)),
        ],
      ),
    );
  }
}

class RecipeImportStoppedPanel extends StatelessWidget {
  const RecipeImportStoppedPanel({required this.onType, super.key});

  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeImportController>();
    final failure = controller.failure;
    final isPhoto = controller.way == RecipeImportWay.snap;
    final (title, message) = switch (failure) {
      RecipeImportFailure(problem: RecipeImportProblem.noRecipe) when isPhoto =>
        (
          RecipeImportCopy.notARecipePhotoTitle,
          RecipeImportCopy.notARecipePhotoBody,
        ),
      RecipeImportFailure(:final problem) => (
        RecipeImportCopy.title(problem),
        RecipeImportCopy.problem(problem),
      ),
      final AppFailure other => (
        RecipeImportCopy.stoppedTitle,
        AppCopy.failure(other),
      ),
      null => (RecipeImportCopy.stoppedTitle, ''),
    };
    return ListView(
      key: const ValueKey('recipe-import-stopped'),
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestRiseIn(
          child: NestCard(
            variant: NestCardVariant.tinted,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NestIconTile(
                  icon: LucideIcons.circleSlash,
                  tint: NestTileTint.butter,
                ),
                const SizedBox(height: NestSpace.md),
                Text(
                  title,
                  style: nest.text.title.copyWith(color: nest.colors.ink),
                ),
                const SizedBox(height: NestSpace.sm),
                Text(
                  message,
                  style: nest.text.body.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        if (controller.canRetry) ...[
          NestButton(
            key: const ValueKey('recipe-import-retry'),
            label: RecipeImportCopy.tryAgain,
            icon: LucideIcons.refreshCw,
            onPressed: controller.retry,
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        if (controller.canSnapInstead) ...[
          NestButton(
            key: const ValueKey('recipe-import-screenshot'),
            label: isPhoto
                ? RecipeImportCopy.tryAnotherPhoto
                : RecipeImportCopy.snapScreenshot,
            icon: LucideIcons.camera,
            variant: controller.canRetry
                ? NestButtonVariant.tonal
                : NestButtonVariant.primary,
            onPressed: controller.useScreenshot,
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        NestButton(
          key: const ValueKey('recipe-import-type'),
          label: RecipeImportCopy.typeIt,
          icon: LucideIcons.pencilLine,
          variant: NestButtonVariant.outline,
          onPressed: onType,
        ),
      ],
    );
  }
}
