import '../model/allergy.dart';
import '../model/allergy_draft.dart';
import '../model/dietary_flag.dart';
import '../model/family_profile.dart';
import '../model/medication.dart';
import '../model/member_health.dart';
import '../model/school.dart';

/// Family profiles as Firestore holds them (family-profiles ADR-0001). The
/// read half is the contract other features consume — lunch-box, nanny-hub,
/// subscriptions — through `FamilyRoster`; see the overview's *Contracts*.
///
/// Every write names only the fields it moves and merges into the document, so
/// a profile is created by its first edit and two people editing two sections
/// never overwrite each other. Allergies and medicines are written one key at
/// a time for the same reason.
abstract interface class FamilyProfileRepository {
  /// One profile per member at most, so the member limit bounds this too
  /// (`BE-08`).
  static const profileLimit = 50;

  /// More schools than any household has children.
  static const schoolLimit = 20;

  /// Every profile in the household, live — or, with [onlyMemberId], that
  /// one profile as a list of at most one: what a viewer whose grant is `own`
  /// may read, asked for exactly, because a rule is not a filter (household
  /// ADR-0003).
  Stream<List<FamilyProfile>> watchProfiles(
    String householdId, {
    String? onlyMemberId,
  });

  /// The household's schools, live, by name.
  Stream<List<School>> watchSchools(String householdId);

  /// One member's medication, live; an empty `MemberHealth` when nothing has
  /// been recorded. Refused by the rules for a viewer who may not see it —
  /// ask `FamilyAccess.canSeeHealth` first (family-profiles ADR-0002).
  Stream<MemberHealth> watchHealth({
    required String householdId,
    required String memberId,
  });

  Future<void> saveFood({
    required String householdId,
    required String memberId,
    required List<String> likes,
    required List<String> dislikes,
    required Set<DietaryFlag> diet,
  });

  /// Adds an allergy, or — with [replacing] — changes one, in one write.
  /// Changing peanuts to sesame, or a fixed allergen to a free-text one,
  /// removes the old entry in the same write that adds the new, so nobody ever
  /// sees both or neither.
  Future<void> saveAllergy({
    required String householdId,
    required String memberId,
    required AllergyDraft draft,
    Allergy? replacing,
  });

  Future<void> removeAllergy({
    required String householdId,
    required String memberId,
    required Allergy allergy,
  });

  /// Where somebody goes to school, and which grade. Either may be null.
  Future<void> saveSchooling({
    required String householdId,
    required String memberId,
    String? schoolId,
    String? grade,
  });

  Future<void> saveSizes({
    required String householdId,
    required String memberId,
    String? clothingSize,
    String? shoeSize,
  });

  /// Adds a medicine when [medicationId] is null, or replaces that one.
  Future<void> saveMedication({
    required String householdId,
    required String memberId,
    String? medicationId,
    required Medication medication,
  });

  Future<void> removeMedication({
    required String householdId,
    required String memberId,
    required String medicationId,
  });

  /// Returns the new school's id, so the sheet that made it can choose it.
  Future<String> addSchool({
    required String householdId,
    required String name,
    required bool nutFree,
  });

  Future<void> updateSchool({
    required String householdId,
    required String schoolId,
    required String name,
    required bool nutFree,
  });

  Future<void> deleteSchool({
    required String householdId,
    required String schoolId,
  });
}
