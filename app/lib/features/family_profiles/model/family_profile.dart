import 'package:freezed_annotation/freezed_annotation.dart';

import 'allergen.dart';
import 'allergen_map_converter.dart';
import 'allergy.dart';
import 'allergy_detail.dart';
import 'allergy_severity.dart';
import 'dietary_flag.dart';
import 'dietary_flags_converter.dart';
import 'other_allergy.dart';
import 'readable_json.dart';

part 'family_profile.freezed.dart';
part 'family_profile.g.dart';

/// What the household knows about one member, at
/// `households/{id}/familyProfiles/{memberId}` (family-profiles ADR-0001).
///
/// It extends a member and never replaces one: the name, colour, role and
/// birthday stay on the member document, which household owns. The document id
/// **is** the member id. Every field is optional, and a member with no document
/// has `FamilyProfile.empty` — a profile nobody has filled in yet is ordinary.
///
/// Medication is not here. It lives in `MemberHealth`, a second document the
/// rules let fewer people read.
@freezed
abstract class FamilyProfile with _$FamilyProfile {
  const factory FamilyProfile({
    @JsonKey(includeToJson: false) required String id,

    /// Set by a parent. What subscriptions counts, and what the family screen
    /// groups by — being a child is not a role (family-profiles ADR-0001).
    @Default(false) bool isChild,
    @Default(<String>[]) List<String> likes,
    @Default(<String>[]) List<String> dislikes,
    @DietaryFlagsConverter() @Default(<DietaryFlag>{}) Set<DietaryFlag> diet,
    @AllergenMapConverter()
    @Default(<Allergen, AllergyDetail>{})
    Map<Allergen, AllergyDetail> allergies,
    @Default(<String, OtherAllergy>{}) Map<String, OtherAllergy> otherAllergies,

    /// A `School` in this household, or null. A school that has since been
    /// deleted reads as no school (`FamilyRoster`).
    String? schoolId,
    String? grade,
    String? clothingSize,
    String? shoeSize,
  }) = _FamilyProfile;

  const FamilyProfile._();

  /// Reads a stored profile. An allergen code this build does not know is
  /// shown as a free-text allergy under its code rather than dropped: a newer
  /// build added it, and hiding an allergy is the one failure this feature
  /// must not have (`BE-10`). See `readableProfileJson`.
  factory FamilyProfile.fromJson(Map<String, Object?> json) =>
      _$FamilyProfileFromJson(readableProfileJson(json));

  factory FamilyProfile.empty(String memberId) => FamilyProfile(id: memberId);

  /// As many free-text allergies as the rules keep. The fixed nine are bounded
  /// by being nine.
  static const otherAllergyLimit = 10;

  /// Every allergy, most dangerous first — what a screen, a lunch planner and
  /// a carer's card all show.
  List<Allergy> get allAllergies => [
    for (final MapEntry(:key, :value) in allergies.entries)
      Allergy.known(key, value),
    for (final MapEntry(:key, :value) in otherAllergies.entries)
      Allergy.other(key, value),
  ]..sort(Allergy.bySeverity);

  bool get canAddOtherAllergy => otherAllergies.length < otherAllergyLimit;

  bool get hasAllergies => allergies.isNotEmpty || otherAllergies.isNotEmpty;

  bool get hasSevereAllergy =>
      allAllergies.any((allergy) => allergy.severity == AllergySeverity.severe);

  bool get hasFood =>
      likes.isNotEmpty || dislikes.isNotEmpty || diet.isNotEmpty;

  bool get hasSizes => clothingSize != null || shoeSize != null;

  bool get hasSchool => schoolId != null || grade != null;
}
