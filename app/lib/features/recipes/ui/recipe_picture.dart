import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../data/recipe_photo_source.dart';

/// A recipe's photo from Storage, filling whatever frame it is put in — the
/// frame fixes the shape, so nothing moves when the picture arrives
/// (`FE-18`). A warm placeholder with a quiet glyph stands in while it loads
/// and for a recipe that has none; the photo fades in over it, or shows at
/// once when it has been read before.
///
/// It asks for the bytes when it is first placed or handed a new [path],
/// never in a build (`FE-05`); the source keeps every picture once read.
class RecipePicture extends StatefulWidget {
  const RecipePicture({required this.path, this.previewPath, super.key});

  /// The Storage object path — the recipe's `card` or `hero` — or null for a
  /// recipe without a photo.
  final String? path;

  /// A smaller cut of the same photo — the `card` under a `hero` — shown
  /// while [path] arrives, so a page opened from its card keeps the picture
  /// the card had.
  final String? previewPath;

  @override
  State<RecipePicture> createState() => _RecipePictureState();
}

class _RecipePictureState extends State<RecipePicture> {
  Future<Uint8List?>? _bytes;
  Future<Uint8List?>? _preview;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void didUpdateWidget(RecipePicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.previewPath != widget.previewPath) {
      _ask();
    }
  }

  void _ask() {
    final source = context.read<RecipePhotoSource>();
    final path = widget.path;
    final previewPath = widget.previewPath;
    _bytes = path == null ? null : source.photo(path);
    _preview = previewPath == null ? null : source.photo(previewPath);
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
    final preview = _preview;
    final bytes = _bytes;
    final under = preview == null
        ? placeholder
        : NestPhotoBytes(bytes: preview, under: placeholder);
    return bytes == null ? under : NestPhotoBytes(bytes: bytes, under: under);
  }
}
