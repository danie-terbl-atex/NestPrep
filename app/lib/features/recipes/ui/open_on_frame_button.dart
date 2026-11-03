import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/cook_along_copy.dart';
import '../../photo_frames/state/frame_availability.dart';
import '../../photo_frames/ui/cook_along_teaser_sheet.dart';
import '../../photo_frames/ui/share_to_frame_sheet.dart';
import '../model/recipe.dart';
import '../model/recipe_scale.dart';
import 'recipe_frame_share.dart';

class OpenOnFrameButton extends StatelessWidget {
  const OpenOnFrameButton({
    required this.recipe,
    required this.scale,
    super.key,
  });

  final Recipe recipe;
  final RecipeScale scale;

  @override
  Widget build(BuildContext context) {
    final state =
        context.watch<FrameAvailability?>()?.state ??
        FrameAvailabilityState.hidden;
    // The frame builds its recipe from the catalogue; a household's own
    // recipe isn't there to build.
    if (recipe.isAiDrafted) return const SizedBox.shrink();
    return switch (state) {
      FrameAvailabilityState.hidden ||
      FrameAvailabilityState.loading => const SizedBox.shrink(),
      FrameAvailabilityState.none => const Padding(
        padding: EdgeInsets.only(top: NestSpace.lg),
        child: _Teaser(),
      ),
      FrameAvailabilityState.some => Padding(
        padding: const EdgeInsets.only(top: NestSpace.lg),
        child: _Open(recipe: recipe, scale: scale),
      ),
    };
  }
}

class _Open extends StatelessWidget {
  const _Open({required this.recipe, required this.scale});

  final Recipe recipe;
  final RecipeScale scale;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestButton(
          label: CookAlongCopy.openOnFrame,
          icon: LucideIcons.tvMinimal,
          variant: NestButtonVariant.outline,
          onPressed: () => showShareToFrameSheet(
            context: context,
            item: recipeFrameShare(recipe, scale),
          ),
        ),
        const SizedBox(height: NestSpace.xs),
        Text(
          RecipeCopy.forPeople(scale.people),
          textAlign: TextAlign.center,
          style: nest.text.caption,
        ),
      ],
    );
  }
}

class _Teaser extends StatelessWidget {
  const _Teaser();

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: NestCard(
          variant: NestCardVariant.flat,
          padding: const EdgeInsets.all(NestSpace.lg),
          onTap: () => showCookAlongTeaserSheet(context: context),
          child: Row(
            children: [
              const NestIconTile(
                icon: LucideIcons.tvMinimal,
                tint: NestTileTint.butter,
                size: NestSize.avatarMedium,
                iconSize: NestSize.iconSmall,
              ),
              const SizedBox(width: NestSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: NestSpace.sm,
                      runSpacing: NestSpace.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          CookAlongCopy.openOnFrame,
                          style: nest.text.bodyStrong.copyWith(
                            color: c.inkSecondary,
                          ),
                        ),
                        const NestTag(
                          label: CookAlongCopy.homeTag,
                          tone: NestTagTone.accent,
                          icon: LucideIcons.sparkles,
                        ),
                      ],
                    ),
                    const SizedBox(height: NestSpace.xxs),
                    Text(CookAlongCopy.teaserTitle, style: nest.text.caption),
                  ],
                ),
              ),
              const SizedBox(width: NestSpace.sm),
              Icon(LucideIcons.chevronRight, color: c.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
