import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../data/recipe_photo_source.dart';

/// A recipe's photo from Storage, filling whatever frame it is put in — the
/// frame fixes the shape, so nothing moves when the picture arrives
/// (`FE-18`). A warm placeholder with a quiet glyph stands in while it loads
/// and for a recipe that has none; the photo fades in over it.
///
/// It asks for the bytes when it is first placed or handed a new [path],
/// never in a build (`FE-05`); the source keeps every picture once read.
class RecipePicture extends StatefulWidget {
  const RecipePicture({required this.path, super.key});

  /// The Storage object path — the recipe's `card` or `hero` — or null for a
  /// recipe without a photo.
  final String? path;

  @override
  State<RecipePicture> createState() => _RecipePictureState();
}

class _RecipePictureState extends State<RecipePicture> {
  Future<Uint8List?>? _bytes;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void didUpdateWidget(RecipePicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _ask();
  }

  void _ask() {
    final path = widget.path;
    _bytes = path == null
        ? null
        : context.read<RecipePhotoSource>().photo(path);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final placeholder = ColoredBox(
      color: nest.colors.surfaceTint,
      child: Center(
        child: Icon(
          LucideIcons.cookingPot,
          size: NestSize.iconLarge,
          color: nest.colors.outlineStrong,
        ),
      ),
    );
    final bytes = _bytes;
    if (bytes == null) return placeholder;
    return FutureBuilder<Uint8List?>(
      future: bytes,
      builder: (context, snapshot) {
        final photo = snapshot.data;
        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            AnimatedOpacity(
              opacity: photo == null ? 0 : 1,
              duration: NestMotion.of(context).slow,
              curve: NestMotion.enter,
              child: photo == null
                  ? const SizedBox.shrink()
                  : Image.memory(
                      photo,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      excludeFromSemantics: true,
                    ),
            ),
          ],
        );
      },
    );
  }
}
