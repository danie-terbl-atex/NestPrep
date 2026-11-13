import 'package:flutter/foundation.dart';

import '../../../shared/photos/compressed_photo.dart';

@immutable
final class RecipePhotoCuts {
  const RecipePhotoCuts({required this.card, required this.hero});

  final CompressedPhoto card;
  final CompressedPhoto hero;
}
