import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/failure/firebase_failure_mapper.dart';
import '../model/language/helper_language.dart';
import '../model/language/translation_id.dart';
import 'home_care_failure_mapper.dart';
import 'translation_repository.dart';

/// The household's translation cache in Firestore, and
/// `translateHomeCareTexts` for what it lacks (home-care ADR-0006). The only
/// place either answer's raw shape exists (`ENG-09`).
final class FirebaseTranslationRepository implements TranslationRepository {
  FirebaseTranslationRepository(this._firestore, this._functions);

  static const householdsPath = 'households';
  static const translationsPath = 'homeCareTranslations';
  static const callable = 'translateHomeCareTexts';

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<Map<String, String>> cached({
    required String householdId,
    required HelperLanguage language,
    required List<String> texts,
  }) async {
    final cache = _firestore
        .collection(householdsPath)
        .doc(householdId)
        .collection(translationsPath);
    try {
      final snapshots = await Future.wait([
        for (final text in texts)
          cache.doc(translationIdOf(text, language)).get(),
      ]);
      return {
        for (final (index, snapshot) in snapshots.indexed)
          if (snapshot.data()?['text'] case final String translated)
            texts[index]: translated,
      };
    } on FirebaseException catch (error) {
      throw failureFromFirebase(error);
    }
  }

  @override
  Future<Map<String, String>> translate({
    required String householdId,
    required HelperLanguage language,
    required List<String> texts,
  }) async {
    try {
      final result = await _functions.httpsCallable(callable).call<Object?>({
        'householdId': householdId,
        'language': language.code,
        'texts': texts,
      });
      return _parse(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw failureFromHomeCareCallable(error);
    }
  }

  /// `{translations: [{text, translated}]}`, read without a cast; anything
  /// else is the Function and the app disagreeing, which is our bug.
  static Map<String, String> _parse(Object? data) {
    if (data case {'translations': final List<Object?> lines}) {
      return {
        for (final line in lines)
          if (line case {
            'text': final String text,
            'translated': final String translated,
          })
            text: translated,
      };
    }
    throw UnknownFailure(FormatException('an unreadable translation', data));
  }
}
