import '../model/language/helper_language.dart';
import '../model/language/helper_profile.dart';

/// Each member's home-care language (home-care ADR-0006).
abstract interface class HelperProfileRepository {
  /// More profiles than a household has members (`BE-08`).
  static const profileLimit = 60;

  /// Everybody's — for whoever may `view` home care, which is who the rules
  /// let read them all.
  Stream<List<HelperProfile>> watchProfiles(String householdId);

  /// One member's, or null while she has chosen nothing — what an `own`
  /// helper may read of her own.
  Stream<HelperProfile?> watchProfile(String householdId, String memberId);

  /// Sets [memberId]'s language, in [by]'s name.
  Future<void> setLanguage({
    required String householdId,
    required String memberId,
    required HelperLanguage language,
    required String by,
  });
}
