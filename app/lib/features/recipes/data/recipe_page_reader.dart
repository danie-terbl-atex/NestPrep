import 'dart:isolate';

import '../../../shared/failure/app_failure.dart';
import '../model/recipe_page.dart';
import 'guarded_web_fetch.dart';
import 'recipe_page_extractor.dart';

abstract interface class RecipePageReader {
  /// Throws a `RecipeImportFailure`: refused, not found, unreachable, not a
  /// public link, or no recipe.
  Future<RecipePage> read(String url);
}

final class HttpRecipePageReader implements RecipePageReader {
  const HttpRecipePageReader(this._fetch);

  final GuardedWebFetch _fetch;

  static const _maxBytes = 3 * 1024 * 1024;

  static bool _isHtml(String? contentType) {
    final type = contentType?.toLowerCase() ?? 'text/html';
    return type.contains('text/html') || type.contains('application/xhtml');
  }

  @override
  Future<RecipePage> read(String url) async {
    final file = await _fetch.get(
      url,
      maxBytes: _maxBytes,
      accept: 'text/html,application/xhtml+xml',
      accepts: _isHtml,
    );
    final finalUrl = file.url;
    final bytes = file.bytes;
    final contentType = file.contentType;
    final RecipePage? page;
    try {
      page = await Isolate.run(
        () => extractRecipePage(
          url: finalUrl,
          html: decodedPage(bytes, contentType),
        ),
      );
    } on Object {
      // A stranger's page is not allowed to take the screen down with it.
      throw const RecipeImportFailure(RecipeImportProblem.noRecipe);
    }
    if (page == null) {
      throw const RecipeImportFailure(RecipeImportProblem.noRecipe);
    }
    return page;
  }
}
