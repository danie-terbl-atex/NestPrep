import '../../../shared/text/normalised_name.dart';
import '../../legal/model/legal_versions.dart';
import '../data/child_profile_directory.dart';
import '../data/family_profile_repository.dart';
import '../model/allergy.dart';
import '../model/allergy_draft.dart';
import '../model/dietary_flag.dart';

/// Every change the family screens make to a profile or a school, each run
/// through the controller's one action runner so a refusal becomes a banner
/// rather than an exception (`FE-09`).
///
/// Text is tidied here, visibly: what a sheet shows is what is saved, and the
/// sheet already trimmed and de-duplicated it as the person typed (`FE-10`).
/// This is the second line, for a caller that did not.
final class FamilyEdits {
  FamilyEdits({
    required FamilyProfileRepository familyProfileRepository,
    required ChildProfileDirectory childProfileDirectory,
    required this.householdId,
    required Future<void> Function(Future<void> Function() action) runAction,
  }) : _repository = familyProfileRepository,
       _children = childProfileDirectory,
       _run = runAction;

  final FamilyProfileRepository _repository;

  /// Who is a child goes through a Function, because the free tier counts
  /// it (subscriptions ADR-0001); a second child on a free household comes
  /// back as `PremiumRequiredFailure`, which the screen answers with the
  /// paywall rather than a banner.
  final ChildProfileDirectory _children;
  final String householdId;
  final Future<void> Function(Future<void> Function() action) _run;

  /// As many likes or dislikes as a card can show and a parent will keep up
  /// to date. The rules hold the same number.
  static const listLimit = 30;

  /// [withGuardianConsent] says the parent has just consented to this
  /// child's information being kept (accounts ADR-0005).
  Future<void> setIsChild(
    String memberId, {
    required bool isChild,
    bool withGuardianConsent = false,
  }) => _run(
    () => _children.setIsChild(
      householdId: householdId,
      memberId: memberId,
      isChild: isChild,
      guardianConsentVersion: withGuardianConsent
          ? LegalVersions.privacy
          : null,
    ),
  );

  Future<void> saveFood(
    String memberId, {
    required List<String> likes,
    required List<String> dislikes,
    required Set<DietaryFlag> diet,
  }) => _run(
    () => _repository.saveFood(
      householdId: householdId,
      memberId: memberId,
      likes: tidyList(likes),
      dislikes: tidyList(dislikes),
      diet: diet,
    ),
  );

  Future<void> saveAllergy(
    String memberId,
    AllergyDraft draft, {
    Allergy? replacing,
  }) => _run(
    () => _repository.saveAllergy(
      householdId: householdId,
      memberId: memberId,
      draft: draft,
      replacing: replacing,
    ),
  );

  Future<void> removeAllergy(String memberId, Allergy allergy) => _run(
    () => _repository.removeAllergy(
      householdId: householdId,
      memberId: memberId,
      allergy: allergy,
    ),
  );

  Future<void> saveSchooling(
    String memberId, {
    String? schoolId,
    String? grade,
  }) => _run(
    () => _repository.saveSchooling(
      householdId: householdId,
      memberId: memberId,
      schoolId: schoolId,
      grade: tidyText(grade),
    ),
  );

  Future<void> saveSizes(
    String memberId, {
    String? clothingSize,
    String? shoeSize,
  }) => _run(
    () => _repository.saveSizes(
      householdId: householdId,
      memberId: memberId,
      clothingSize: tidyText(clothingSize),
      shoeSize: tidyText(shoeSize),
    ),
  );

  /// Adds a school and answers with its id, or null when the write was
  /// refused — the refusal is already on the screen as a banner.
  Future<String?> addSchool({
    required String name,
    required bool nutFree,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    String? created;
    await _run(() async {
      created = await _repository.addSchool(
        householdId: householdId,
        name: trimmed,
        nutFree: nutFree,
      );
    });
    return created;
  }

  Future<void> updateSchool(
    String schoolId, {
    required String name,
    required bool nutFree,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return _run(
      () => _repository.updateSchool(
        householdId: householdId,
        schoolId: schoolId,
        name: trimmed,
        nutFree: nutFree,
      ),
    );
  }

  Future<void> deleteSchool(String schoolId) => _run(
    () =>
        _repository.deleteSchool(householdId: householdId, schoolId: schoolId),
  );

  /// Blank is absent: an empty grade is no grade, stored as null.
  static String? tidyText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Trimmed, blanks dropped, and each thing once however it was capitalised
  /// — "Pasta" and "pasta " are one like. The first spelling is kept.
  static List<String> tidyList(List<String> values) {
    final seen = <String>{};
    return [
      for (final value in values)
        if (value.trim().isNotEmpty && seen.add(normalisedName(value)))
          value.trim(),
    ].take(listLimit).toList();
  }
}
