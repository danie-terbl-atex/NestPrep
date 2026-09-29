import '../../../shared/copy/app_copy.dart';
import '../model/allergy.dart';

/// What an allergy is called on screen: the copy for one of the fixed nine, or
/// the household's own words for anything else.
String allergyName(Allergy allergy) {
  final allergen = allergy.allergen;
  return allergen == null
      ? allergy.otherName ?? ''
      : FamilyCopy.allergenName(allergen);
}
