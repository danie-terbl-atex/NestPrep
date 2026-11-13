import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../data/recipe_photo_picker.dart';
import '../model/recipe_form.dart';
import '../state/recipe_builder_controller.dart';
import 'recipe_builder_page_pictures.dart';
import 'recipe_picture.dart';

class RecipeBuilderPhotos extends StatelessWidget {
  const RecipeBuilderPhotos({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeBuilderController>();
    final form = controller.form;
    final photos = form.photos;
    final isBusy = controller.isAddingPhotos || controller.isSaving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(OwnRecipeCopy.photosHint, style: nest.text.caption),
        const RecipeBuilderPagePictures(),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: NestSpace.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, photo) in photos.indexed) ...[
                  if (index > 0) const SizedBox(width: NestSpace.md),
                  _PhotoTile(
                    key: ValueKey(photo.photoId),
                    photo: photo,
                    number: index + 1,
                    isCover: index == 0,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: NestSpace.md),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            NestButton(
              key: const ValueKey('recipe-photo-take'),
              label: OwnRecipeCopy.takePhoto,
              icon: LucideIcons.camera,
              variant: NestButtonVariant.outline,
              size: NestButtonSize.medium,
              isExpanded: false,
              isLoading: controller.isAddingPhotos,
              onPressed: isBusy || !form.canAddPhoto
                  ? null
                  : () => controller.addPhotos(RecipePhotoOrigin.camera),
            ),
            NestButton(
              key: const ValueKey('recipe-photo-choose'),
              label: OwnRecipeCopy.choosePhotos,
              icon: LucideIcons.images,
              variant: NestButtonVariant.outline,
              size: NestButtonSize.medium,
              isExpanded: false,
              onPressed: isBusy || !form.canAddPhoto
                  ? null
                  : () => controller.addPhotos(RecipePhotoOrigin.library),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.number,
    required this.isCover,
    super.key,
  });

  final RecipeFormPhoto photo;
  final int number;
  final bool isCover;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<RecipeBuilderController>();
    return SizedBox(
      width: NestSize.shelfCardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                NestPhotoFrame(
                  radius: NestRadius.lg,
                  semanticsLabel: OwnRecipeCopy.photoNumbered(
                    number,
                    controller.form.photos.length,
                  ),
                  child: switch (photo) {
                    NewRecipeFormPhoto(:final cuts) => Image.memory(
                      cuts.card.bytes,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                    KeptRecipeFormPhoto(:final stored) => RecipePicture(
                      path: stored.card,
                    ),
                  },
                ),
                if (isCover)
                  const PositionedDirectional(
                    start: NestSpace.sm,
                    top: NestSpace.sm,
                    child: NestTag(
                      label: OwnRecipeCopy.coverTag,
                      tone: NestTagTone.accent,
                    ),
                  ),
                PositionedDirectional(
                  end: NestSpace.xs,
                  top: NestSpace.xs,
                  child: NestIconButton(
                    icon: LucideIcons.x,
                    label: OwnRecipeCopy.removePhoto(number),
                    onPressed: () => controller.update(
                      (form) => form.withoutPhoto(photo.photoId),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isCover)
            NestButton(
              label: OwnRecipeCopy.makeCover,
              variant: NestButtonVariant.link,
              size: NestButtonSize.small,
              onPressed: () =>
                  controller.update((form) => form.withCover(photo.photoId)),
            ),
        ],
      ),
    );
  }
}
