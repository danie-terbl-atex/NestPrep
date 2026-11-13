import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import 'recipe_draft.dart';

/// A recipe the first read found in a PDF (recipes ADR-0009): its own pages,
/// and the pages of a preparation it builds on, such as a base dough.
@immutable
final class FoundDocumentRecipe {
  const FoundDocumentRecipe({
    required this.name,
    required this.summary,
    required this.pages,
    this.usesPages = const [],
  });

  final String name;
  final String summary;
  final List<int> pages;
  final List<int> usesPages;

  List<int> get readPages => [...usesPages, ...pages];

  int get firstPage => pages.first;
}

@immutable
final class RecipeDocumentScan {
  const RecipeDocumentScan({required this.recipes, required this.callsLeft});

  final List<FoundDocumentRecipe> recipes;
  final int callsLeft;
}

/// `[ymin, xmin, ymax, xmax]` on 0–1000, the way the model gives a box.
@immutable
final class DocumentPhotoBox {
  const DocumentPhotoBox({
    required this.top,
    required this.left,
    required this.bottom,
    required this.right,
  });

  final int top;
  final int left;
  final int bottom;
  final int right;
}

@immutable
final class DocumentPhoto {
  const DocumentPhoto({required this.page, required this.box});

  final int page;
  final DocumentPhotoBox box;
}

@immutable
final class DocumentRecipeReading {
  const DocumentRecipeReading({
    required this.draft,
    required this.photo,
    required this.callsLeft,
  });

  final RecipeDraft? draft;
  final DocumentPhoto? photo;
  final int callsLeft;
}

/// One page, once as a picture to find the recipes on.
@immutable
final class DocumentScanPage {
  const DocumentScanPage({required this.number, required this.jpeg});

  final int number;
  final Uint8List jpeg;
}

/// One page as a recipe is read from it: two overlapping halves, and the
/// whole page when it may hold the recipe's photo.
@immutable
final class DocumentReadPage {
  const DocumentReadPage({
    required this.number,
    required this.top,
    required this.bottom,
    this.whole,
  });

  final int number;
  final Uint8List top;
  final Uint8List bottom;
  final Uint8List? whole;
}

enum DocumentImportState {
  waiting,
  reading,
  saved,
  notARecipe,
  unfinished,
  failed,
}

@immutable
final class DocumentImportRow {
  const DocumentImportRow({
    required this.recipe,
    this.state = DocumentImportState.waiting,
    this.failure,
    this.draft,
  });

  final FoundDocumentRecipe recipe;
  final DocumentImportState state;
  final AppFailure? failure;

  /// Kept when it could not be saved as it was, to finish in the builder.
  final RecipeDraft? draft;

  bool get isDone => switch (state) {
    DocumentImportState.waiting || DocumentImportState.reading => false,
    _ => true,
  };

  DocumentImportRow moveTo(
    DocumentImportState state, {
    AppFailure? failure,
    RecipeDraft? draft,
  }) => DocumentImportRow(
    recipe: recipe,
    state: state,
    failure: failure,
    draft: draft,
  );
}
