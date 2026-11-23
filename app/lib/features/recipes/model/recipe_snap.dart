import 'package:flutter/foundation.dart';

import 'recipe_document.dart';

/// One photo or screenshot of a recipe, cut into the overlapping JPEG parts
/// the model reads (recipes ADR-0010). It lives in memory until it is read.
final class RecipeSnap {
  const RecipeSnap({
    required this.parts,
    required this.thumbnail,
    required this.layout,
    this.whole,
  });

  final List<Uint8List> parts;
  final Uint8List thumbnail;
  final RecipeSnapLayout layout;

  /// The photo in one piece, for a read of this photo alone. Null when it is
  /// too long to be read that way.
  final Uint8List? whole;

  /// The server's `MAX_SNAP_PHOTOS`, `MAX_SNAP_PARTS` and
  /// `MAX_SNAP_PART_BYTES`. Every part at its largest still fits one request.
  static const maxPhotos = 8;
  static const maxParts = 40;
  static const maxPartBytes = 160 * 1024;
  static const maxWholeBytes = 1024 * 1024;
}

/// Where the parts sit in the scaled photo: left column first, top to bottom.
@immutable
final class RecipeSnapLayout {
  const RecipeSnapLayout({
    required this.width,
    required this.height,
    required this.partWidth,
    required this.partHeight,
    required this.lefts,
    required this.tops,
  });

  final int width;
  final int height;
  final int partWidth;
  final int partHeight;
  final List<int> lefts;
  final List<int> tops;

  int get partCount => lefts.length * tops.length;

  (int, int) originOf(int part) =>
      (lefts[part ~/ tops.length], tops[part % tops.length]);
}

/// The dish's photograph on a snap (recipes ADR-0011): a box on one part, or
/// on the whole photo when that was sent alone ([part] null). Both count from 1.
@immutable
final class RecipeSnapDish {
  const RecipeSnapDish({required this.photo, required this.box, this.part});

  final int photo;
  final int? part;
  final DocumentPhotoBox box;
}
