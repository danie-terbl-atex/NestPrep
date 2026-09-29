import '../model/language/helper_language.dart';

/// English lines in a helper's language (home-care ADR-0006): the
/// household's cache first, then the Function for what is missing.
abstract interface class TranslationRepository {
  /// The most texts one ask carries — the Function's own bound.
  static const batchLimit = 60;

  /// What the household's cache already holds of [texts] in [language],
  /// English → translation. Served from the phone's offline copy when there
  /// is no signal; a text not there is simply absent.
  Future<Map<String, String>> cached({
    required String householdId,
    required HelperLanguage language,
    required List<String> texts,
  });

  /// Translates [texts] — at most [batchLimit] — through
  /// `translateHomeCareTexts`, which pays for what the cache lacks and
  /// stores it. English → translation.
  Future<Map<String, String>> translate({
    required String householdId,
    required HelperLanguage language,
    required List<String> texts,
  });
}
