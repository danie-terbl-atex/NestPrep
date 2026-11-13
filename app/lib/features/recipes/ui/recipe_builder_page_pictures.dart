import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/recipe_builder_controller.dart';
import '../state/recipe_image_picks.dart';

class RecipeBuilderPagePictures extends StatelessWidget {
  const RecipeBuilderPagePictures({super.key});

  @override
  Widget build(BuildContext context) {
    final picks = context.watch<RecipeImagePicks?>();
    if (picks == null) return const SizedBox.shrink();
    context.watch<RecipeBuilderController>();
    final shown = picks.shown;
    if (shown.isEmpty) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    return Padding(
      key: const ValueKey('recipe-page-pictures'),
      padding: const EdgeInsets.only(top: NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(RecipeImportCopy.picturesTitle, style: nest.text.bodyStrong),
          Text(RecipeImportCopy.picturesHint, style: nest.text.caption),
          const SizedBox(height: NestSpace.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final (index, pick) in shown.indexed) ...[
                  if (index > 0) const SizedBox(width: NestSpace.sm),
                  _PictureTile(
                    key: ValueKey(pick.url),
                    pick: pick,
                    number: index + 1,
                    isChosen: picks.isChosen(pick),
                    onTap: () => picks.toggle(pick),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PictureTile extends StatelessWidget {
  const _PictureTile({
    required this.pick,
    required this.number,
    required this.isChosen,
    required this.onTap,
    super.key,
  });

  final RecipeImagePick pick;
  final int number;
  final bool isChosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = NestTheme.of(context).colors;
    final cuts = pick.cuts;
    return Semantics(
      button: cuts != null,
      selected: isChosen,
      label: RecipeImportCopy.pictureNumbered(number),
      child: SizedBox.square(
        dimension: NestSize.avatarLarge,
        child: cuts == null
            ? const NestSkeleton(height: NestSize.avatarLarge)
            : GestureDetector(
                onTap: onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NestPhotoFrame(
                      radius: NestRadius.md,
                      child: Image.memory(
                        cuts.card.bytes,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                    ),
                    if (isChosen)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(NestRadius.md),
                          border: Border.all(
                            color: c.accentInk,
                            width: NestStroke.focus,
                          ),
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: Padding(
                            padding: const EdgeInsets.all(NestSpace.xxs),
                            child: Icon(
                              LucideIcons.circleCheck,
                              color: c.accentInk,
                              size: NestSize.iconSmall,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
