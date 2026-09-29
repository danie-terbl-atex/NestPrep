import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/family_profiles/data/firestore_family_profile_repository.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy_draft.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/medication.dart';
import 'package:nestprep/features/household/model/member_role.dart';

import 'household_fixture.dart';

/// The family profile repository against the real Firestore, through the real
/// rules (foundation ADR-0010).
///
/// What no widget test can reach: that every write is a **merge** the rules
/// accept — a profile created by its first one-field edit, an allergy moved
/// from one allergen to another in one write, a medicine added beside
/// another without replacing it — and that what comes back is what went in.
/// The nested-model lesson is the reason: a model handed to Firestore instead
/// of its map fails on a device and nowhere else.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestHousehold home;
  late FirestoreFamilyProfileRepository family;
  late String kidId;

  setUpAll(() async {
    home = await signInAndCreateAHousehold();
    family = FirestoreFamilyProfileRepository(home.firestore);
  });

  setUp(() async {
    home = await home.freshHousehold();
    await home.households.addMember(
      householdId: home.id,
      displayName: 'Kid',
      color: MemberColor.sky,
      role: MemberRole.kid,
    );
    final members = await home.households.watchMembers(home.id).first;
    kidId = members.firstWhere((member) => member.displayName == 'Kid').id;
  });

  tearDownAll(() async => home.signOut());

  Future<FamilyProfile> kid() async =>
      (await family.watchProfiles(home.id).first).firstWhere(
        (profile) => profile.id == kidId,
      );

  test('a first edit of one field creates the profile', () async {
    // Who is a child is the `setChildProfile` callable's alone now — the free
    // tier counts it (subscriptions ADR-0001) — so the first edit here is a
    // like, which any profile editor writes directly.
    await family.saveFood(
      householdId: home.id,
      memberId: kidId,
      likes: const ['Pasta'],
      dislikes: const [],
      diet: const {},
    );
    final profile = await kid();
    expect(profile.isChild, isFalse);
    expect(profile.likes, ['Pasta']);
    expect(profile.allAllergies, isEmpty);
  });

  test('allergies are written one at a time and moved in one write', () async {
    await family.saveAllergy(
      householdId: home.id,
      memberId: kidId,
      draft: const AllergyDraft.known(
        allergen: Allergen.peanut,
        severity: AllergySeverity.severe,
        note: 'Pen in the bag',
      ),
    );
    await family.saveAllergy(
      householdId: home.id,
      memberId: kidId,
      draft: const AllergyDraft.other(
        otherName: 'Kiwi',
        severity: AllergySeverity.mild,
      ),
    );
    final peanut = (await kid()).allAllergies.first;
    expect(peanut.allergen, Allergen.peanut);

    await family.saveAllergy(
      householdId: home.id,
      memberId: kidId,
      draft: const AllergyDraft.known(
        allergen: Allergen.sesame,
        severity: AllergySeverity.moderate,
      ),
      replacing: peanut,
    );
    final profile = await kid();
    expect(profile.allergies.keys, [Allergen.sesame]);
    expect(profile.otherAllergies.values.single.name, 'Kiwi');

    await family.removeAllergy(
      householdId: home.id,
      memberId: kidId,
      allergy: profile.allAllergies.last,
    );
    expect((await kid()).otherAllergies, isEmpty);
  });

  test('food, schooling and sizes round-trip, and blank clears', () async {
    final school = await family.addSchool(
      householdId: home.id,
      name: 'Oakwood',
      nutFree: true,
    );
    await family.saveFood(
      householdId: home.id,
      memberId: kidId,
      likes: const ['Pasta'],
      dislikes: const ['Mushrooms'],
      diet: const {DietaryFlag.halal},
    );
    await family.saveSchooling(
      householdId: home.id,
      memberId: kidId,
      schoolId: school,
      grade: 'Grade 3',
    );
    await family.saveSizes(
      householdId: home.id,
      memberId: kidId,
      clothingSize: '7-8',
      shoeSize: 'UK 13',
    );
    var profile = await kid();
    expect(profile.likes, ['Pasta']);
    expect(profile.diet, {DietaryFlag.halal});
    expect(profile.schoolId, school);
    expect(profile.shoeSize, 'UK 13');

    await family.saveSizes(householdId: home.id, memberId: kidId);
    profile = await kid();
    expect(profile.clothingSize, isNull);
    expect(profile.likes, ['Pasta'], reason: 'a merge touches only its own');

    final schools = await family.watchSchools(home.id).first;
    expect(schools.single.nutFree, isTrue);
  });

  test('medicines are added beside each other, edited and removed', () async {
    await family.saveMedication(
      householdId: home.id,
      memberId: kidId,
      medication: const Medication(name: 'Inhaler', times: [420, 1200]),
    );
    await family.saveMedication(
      householdId: home.id,
      memberId: kidId,
      medication: const Medication(name: 'Antihistamine'),
    );
    var health = await family
        .watchHealth(householdId: home.id, memberId: kidId)
        .first;
    expect(health.medications, hasLength(2));

    final inhaler = health.inOrderOfTheDay.first;
    await family.saveMedication(
      householdId: home.id,
      memberId: kidId,
      medicationId: inhaler.id,
      medication: inhaler.medication.copyWith(times: const [480]),
    );
    await family.removeMedication(
      householdId: home.id,
      memberId: kidId,
      medicationId: health.inOrderOfTheDay.last.id,
    );
    health = await family
        .watchHealth(householdId: home.id, memberId: kidId)
        .first;
    expect(health.medications.values.single.times, [480]);
  });
}
