import '../../features/family_profiles/model/allergen.dart';
import '../../features/family_profiles/model/allergy_severity.dart';
import '../../features/family_profiles/model/dietary_flag.dart';
import '../../features/family_profiles/model/food_rules.dart';

/// Every word the family profiles screens say (`FE-19`). A file of its own,
/// exported from `app_copy.dart`, so a feature this size does not grow the one
/// copy file past what anybody can read — and so parallel features do not all
/// edit the same lines. The copy ratchet reads every file in this folder.
abstract final class FamilyCopy {
  static const title = 'Family profiles';
  static const openFromHousehold = 'Family profiles';
  static const openFromHouseholdBody =
      'Allergies, food, medication, school and sizes for each person.';
  static const children = 'Children';
  static const everyoneElse = 'Everyone else';
  static const emptyTitle = 'Nobody here yet';
  static const emptyBody =
      'Add people on the household screen, then fill in what each of them '
      'eats and needs.';
  static const nothingRecorded = 'Nothing recorded yet';
  static const noChildrenYet =
      'Open somebody’s profile and mark them as a child — children are who '
      'lunches are planned for.';
  static const memberGoneTitle = 'This person has left the household';
  static const memberGoneBody =
      'Their profile went with them. Go back to see who is here now.';
  static const privacyNote =
      'Everyone in the household sees allergies, food, school and sizes. '
      'Medication is for parents and the person themselves.';

  static String age(int years) => years == 1 ? '1 year' : '$years years';

  static const isChild = 'Child';
  static const isChildHint = 'Children are who lunches are planned for.';
  static const markAsChild = 'This is a child';

  static const sectionAllergies = 'Allergies';
  static const sectionFood = 'Food';
  static const sectionMedication = 'Medication';
  static const sectionSchool = 'School';
  static const sectionSizes = 'Sizes';

  static String editSection(String section) => 'Edit ${section.toLowerCase()}';

  static const save = 'Save';
  static const cancel = 'Cancel';
  static const remove = 'Remove';

  // Allergies.
  static const addAllergy = 'Add an allergy';
  static const editAllergy = 'Edit allergy';
  static const removeAllergyConfirm = 'Remove this allergy?';
  static const noAllergies = 'No allergies recorded';
  static const allergenLabel = 'Allergic to';
  static const allergenOther = 'Something else';
  static const otherAllergyName = 'What are they allergic to?';
  static const otherAllergyNameHint = 'Kiwi, bee stings, penicillin…';
  static const severityLabel = 'How serious is it?';
  static const allergyNote = 'What to do (optional)';
  static const allergyNoteHint =
      'Adrenaline pen in the school bag, antihistamine in the kitchen drawer';

  static String allergenName(Allergen allergen) => switch (allergen) {
    Allergen.peanut => 'Peanuts',
    Allergen.treeNut => 'Tree nuts',
    Allergen.milk => 'Milk',
    Allergen.egg => 'Eggs',
    Allergen.wheat => 'Wheat and gluten',
    Allergen.soy => 'Soy',
    Allergen.fish => 'Fish',
    Allergen.shellfish => 'Shellfish',
    Allergen.sesame => 'Sesame',
  };

  static String severityName(AllergySeverity severity) => switch (severity) {
    AllergySeverity.mild => 'Mild',
    AllergySeverity.moderate => 'Moderate',
    AllergySeverity.severe => 'Severe',
  };

  static String severityHelp(AllergySeverity severity) => switch (severity) {
    AllergySeverity.mild => 'Discomfort — an upset tummy, an itch.',
    AllergySeverity.moderate =>
      'A reaction that needs treating, like hives or swelling.',
    AllergySeverity.severe =>
      'Life-threatening. Call for help and use the adrenaline pen.',
  };

  /// The line at the top of a profile when any allergy is severe. It names
  /// them, because "severe allergy" alone sends somebody looking.
  static String severeWarning(List<String> names) =>
      'Severe allergy: ${names.join(', ')}. Check every label.';

  static String moreAllergies(int count) => '+$count more';

  // Food.
  static const editFood = 'Food and diet';
  static const likes = 'Likes';
  static const dislikes = 'Won’t eat';
  static const diet = 'Diet';
  static const noFood = 'No likes, dislikes or diet yet';
  static const addLike = 'Add something they love';
  static const addDislike = 'Add something they won’t eat';
  static const addChip = 'Add';

  static String removeChip(String name) => 'Remove $name';

  static const listFull = 'That is as many as a list holds.';

  static String dietName(DietaryFlag flag) => switch (flag) {
    DietaryFlag.nutFree => 'Nut-free',
    DietaryFlag.vegetarian => 'Vegetarian',
    DietaryFlag.vegan => 'Vegan',
    DietaryFlag.halal => 'Halal',
    DietaryFlag.kosher => 'Kosher',
    DietaryFlag.noPork => 'No pork',
    DietaryFlag.glutenFree => 'Gluten-free',
    DietaryFlag.dairyFree => 'Dairy-free',
  };

  static const nutFree = 'Nut-free';

  static String nutFreeReason(NutFreeReason reason) => switch (reason) {
    NutFreeReason.allergy => 'nut allergy',
    NutFreeReason.diet => 'family rule',
    NutFreeReason.school => 'school rule',
  };

  /// "Nut-free · school rule", naming every reason that holds, so the person
  /// packing a lunch knows whether it is the school or the child.
  static String nutFreeBecause(Iterable<NutFreeReason> reasons) =>
      '$nutFree · ${reasons.map(nutFreeReason).join(', ')}';

  // Medication.
  static const noMedication = 'No medication recorded';
  static const addMedication = 'Add a medicine';
  static const editMedication = 'Edit medicine';
  static const removeMedicationConfirm = 'Remove this medicine?';
  static const medicationName = 'Medicine';
  static const medicationNameHint = 'The name on the box';
  static const medicationDose = 'Dose (optional)';
  static const medicationDoseHint = '5 ml, one puff, half a tablet';
  static const medicationTimes = 'When';
  static const medicationAddTime = 'Add a time';
  static const medicationWhenNeeded = 'When needed';
  static const medicationWhenNeededHint =
      'No times means it is given when needed, like an inhaler.';
  static const medicationNote = 'Note (optional)';
  static const medicationNoteHint = 'With food. Keep in the fridge.';
  static const medicationHiddenTitle = 'Medication is private';
  static const medicationHiddenBody =
      'Parents see medication. A helper sees it once the household allows it.';

  static String removeTime(String time) => 'Remove $time';

  // School.
  static const noSchool = 'No school or grade yet';
  static const schoolLabel = 'School';
  static const schoolNone = 'None';
  static const grade = 'Grade (optional)';
  static const gradeHint = 'Grade 3, Grade R';
  static const addSchool = 'Add a school';
  static const schoolName = 'School name';
  static const schoolNutFree = 'Nut-free school';
  static const schoolNutFreeHelp =
      'Every child at this school gets the nut-free rule.';
  static const editSchool = 'Edit school';
  static const deleteSchool = 'Delete school';
  static const deleteSchoolConfirm = 'Delete this school?';
  static const schoolsTitle = 'Schools';
  static const schoolsEmpty =
      'Add a school once, and mark it nut-free if it is — every child at it '
      'gets the rule.';

  static String deleteSchoolBody(int pupils) => pupils == 0
      ? 'Nobody is at this school.'
      : pupils == 1
      ? 'One person is at this school. They will have no school until you '
            'choose another.'
      : '$pupils people are at this school. They will have no school until '
            'you choose another.';

  static String schoolWithGrade(String? school, String? grade) =>
      [?school, ?grade].join(' · ');

  // Sizes.
  static const noSizes = 'No sizes recorded';
  static const sizeNotSet = 'Not set';
  static const clothingSize = 'Clothes';
  static const clothingSizeHint = 'Age 7–8, or S';
  static const shoeSize = 'Shoes';
  static const shoeSizeHint = 'UK 13';
}
