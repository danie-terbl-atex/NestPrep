import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/recipe_photo.dart';
import 'recipe_picture.dart';

class RecipeGallery extends StatefulWidget {
  const RecipeGallery({required this.photos, super.key});

  final List<RecipePhoto> photos;

  @override
  State<RecipeGallery> createState() => _RecipeGalleryState();
}

class _RecipeGalleryState extends State<RecipeGallery> {
  var _showing = 0;

  @override
  Widget build(BuildContext context) {
    final count = widget.photos.length;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          key: const ValueKey('recipe-gallery'),
          itemCount: count,
          onPageChanged: (page) => setState(() => _showing = page),
          itemBuilder: (context, page) => Semantics(
            label: OwnRecipeCopy.photoNumbered(page + 1, count),
            image: true,
            child: RecipePicture(
              path: widget.photos[page].hero,
              previewPath: widget.photos[page].card,
            ),
          ),
        ),
        PositionedDirectional(
          end: NestSpace.lg,
          bottom: NestRadius.xxl + NestSpace.sm,
          child: ExcludeSemantics(
            child: NestTag(label: '${_showing + 1} / $count'),
          ),
        ),
      ],
    );
  }
}
