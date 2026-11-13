import 'package:flutter/foundation.dart';

import '../data/recipe_image_fetcher.dart';
import '../model/recipe_photo_cuts.dart';
import 'recipe_builder_controller.dart';
import 'recipe_photo_intake.dart';

final class RecipeImagePick {
  RecipeImagePick(this.url);

  final String url;
  RecipePhotoCuts? cuts;
  String? photoId;
  bool isLoading = true;
}

/// Fetched up front, through the same guards as the page, because the row has
/// to show them. Which are chosen is read from the form, so a photo removed in
/// the builder is unchosen here too.
final class RecipeImagePicks extends ChangeNotifier {
  RecipeImagePicks({
    required this._builder,
    required this._fetcher,
    required this._intake,
    required List<String> urls,
    required this.credit,
    required this.sourceUrl,
  }) : _picks = [for (final url in urls) RecipeImagePick(url)] {
    final fetches = [for (final pick in _picks) _load(pick)];
    if (fetches.isNotEmpty) _builder.holdSaveFor(fetches.first);
  }

  final RecipeBuilderController _builder;
  final RecipeImageFetcher _fetcher;
  final RecipePhotoIntake _intake;
  final List<RecipeImagePick> _picks;
  final String? credit;
  final String? sourceUrl;
  bool _isDisposed = false;

  List<RecipeImagePick> get shown => [
    for (final pick in _picks)
      if (pick.isLoading || pick.cuts != null) pick,
  ];

  bool isChosen(RecipeImagePick pick) =>
      _builder.form.photos.any((photo) => photo.photoId == pick.photoId);

  void toggle(RecipeImagePick pick) {
    final cuts = pick.cuts;
    if (cuts == null) return;
    if (isChosen(pick)) {
      final photoId = pick.photoId!;
      _builder.update((form) => form.withoutPhoto(photoId));
    } else if (_builder.form.canAddPhoto) {
      _choose(pick, cuts);
    }
    notifyListeners();
  }

  void _choose(RecipeImagePick pick, RecipePhotoCuts cuts) {
    pick.photoId = _builder.addPhotoCuts(
      cuts,
      credit: credit,
      sourceUrl: sourceUrl,
    );
  }

  Future<void> _load(RecipeImagePick pick) async {
    final cuts = await _cutsOf(pick.url);
    if (_isDisposed) return;
    pick
      ..cuts = cuts
      ..isLoading = false;
    if (cuts != null && identical(pick, _picks.first)) _choose(pick, cuts);
    notifyListeners();
  }

  Future<RecipePhotoCuts?> _cutsOf(String url) async {
    try {
      final bytes = await _fetcher.fetch(url);
      return bytes == null ? null : await _intake.cut(bytes);
    } on Object {
      // Whatever a stranger's file does to the decoder: no picture, no failure.
      return null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
