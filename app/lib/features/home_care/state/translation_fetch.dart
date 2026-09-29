import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../data/translation_repository.dart';
import '../model/language/helper_language.dart';
import '../model/language/translation_book.dart';

/// Getting lines translated, once each (home-care ADR-0006): the household's
/// cache first — the phone's offline copy included — then the Function for
/// what it lacks, in batches it accepts. Kept apart from the language
/// controller so that file stays about who reads what (`ENG-05`).
final class TranslationFetch extends ChangeNotifier {
  TranslationFetch({required this._repository, required this.householdId});

  final TranslationRepository _repository;
  final String householdId;

  final _books = <HelperLanguage, TranslationBook>{};
  final _asked = <HelperLanguage, Set<String>>{};
  var _inFlight = 0;
  AppFailure? _failure;
  var _isDisposed = false;

  bool get isBusy => _inFlight > 0;

  AppFailure? get failure => _failure;

  TranslationBook bookFor(HelperLanguage language) =>
      _books[language] ?? TranslationBook(language: language);

  /// Asks for whatever of [texts] this language's book lacks and nobody has
  /// asked for yet. A failure stops further asks until [forgetFailure].
  void ensure(HelperLanguage language, Iterable<String> texts) {
    if (_failure != null) return;
    final asked = _asked.putIfAbsent(language, () => {});
    final wanted = [
      for (final text in bookFor(language).missing(texts))
        if (text.trim().isNotEmpty && !asked.contains(text)) text,
    ];
    if (wanted.isEmpty) return;
    asked.addAll(wanted);
    // Screens ask while they build; the work, and the notice that it has
    // started, begin after the build.
    unawaited(Future.microtask(() => _fetch(language, wanted)));
  }

  /// Lets the texts that failed be asked for again.
  void forgetFailure() {
    _failure = null;
    _asked.clear();
    _tell();
  }

  Future<void> _fetch(HelperLanguage language, List<String> texts) async {
    _inFlight++;
    _tell();
    try {
      final cached = await _repository.cached(
        householdId: householdId,
        language: language,
        texts: texts,
      );
      _add(language, cached);
      final missing = [
        for (final text in texts)
          if (!cached.containsKey(text)) text,
      ];
      for (var start = 0; start < missing.length; start += _batch) {
        final batch = missing.sublist(
          start,
          (start + _batch).clamp(0, missing.length),
        );
        _add(
          language,
          await _repository.translate(
            householdId: householdId,
            language: language,
            texts: batch,
          ),
        );
      }
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _inFlight--;
      _tell();
    }
  }

  static const _batch = TranslationRepository.batchLimit;

  void _add(HelperLanguage language, Map<String, String> translated) {
    if (translated.isEmpty) return;
    _books[language] = bookFor(language).adding(translated);
    _tell();
  }

  void _tell() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
