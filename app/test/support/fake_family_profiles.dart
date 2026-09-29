import 'dart:async';

import 'package:nestprep/features/family_profiles/data/family_profile_repository.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/family_profiles/model/allergy.dart';
import 'package:nestprep/features/family_profiles/model/allergy_detail.dart';
import 'package:nestprep/features/family_profiles/model/allergy_draft.dart';
import 'package:nestprep/features/family_profiles/model/allergy_severity.dart';
import 'package:nestprep/features/family_profiles/model/dietary_flag.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/medication.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/model/other_allergy.dart';
import 'package:nestprep/features/family_profiles/model/school.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import 'household_fixtures.dart';

/// Family profiles driven by hand: three live reads a test can make arrive in
/// any order, and a record of every write, so a test asserts what a person's
/// tap asked the backend to do (`FE-20`).
final class FakeFamilyProfileRepository implements FamilyProfileRepository {
  final _profiles = StreamController<List<FamilyProfile>>.broadcast();
  final _schools = StreamController<List<School>>.broadcast();
  final _health = StreamController<MemberHealth>.broadcast();

  /// Set to make the next write fail the way a rules denial does.
  AppFailure? failWritesWith;

  /// Every write, in order, as `(method, arguments)`.
  final writes = <(String, Map<String, Object?>)>[];

  /// Which members' medication was asked for.
  final healthWatched = <String>[];

  void emitProfiles(List<FamilyProfile> profiles) => _profiles.add(profiles);
  void emitSchools(List<School> schools) => _schools.add(schools);
  void emitHealth(MemberHealth health) => _health.add(health);
  void failProfilesWith(Object error) => _profiles.addError(error);
  void failHealthWith(Object error) => _health.addError(error);

  Future<void> close() async {
    await _profiles.close();
    await _schools.close();
    await _health.close();
  }

  @override
  Stream<List<FamilyProfile>> watchProfiles(
    String householdId, {
    String? onlyMemberId,
  }) {
    profilesAskedFor.add(onlyMemberId);
    return _profiles.stream;
  }

  /// Each profile read's scope: null for every profile, else the one member
  /// an `own` grant reads (household ADR-0003).
  final profilesAskedFor = <String?>[];

  /// How many times the schools were asked for.
  var schoolsWatched = 0;

  @override
  Stream<List<School>> watchSchools(String householdId) {
    schoolsWatched++;
    return _schools.stream;
  }

  @override
  Stream<MemberHealth> watchHealth({
    required String householdId,
    required String memberId,
  }) {
    healthWatched.add(memberId);
    return _health.stream;
  }

  Future<void> _record(String method, Map<String, Object?> arguments) async {
    final failure = failWritesWith;
    if (failure != null) {
      failWritesWith = null;
      throw failure;
    }
    writes.add((method, arguments));
  }

  @override
  Future<void> setIsChild({
    required String householdId,
    required String memberId,
    required bool isChild,
  }) => _record('setIsChild', {'memberId': memberId, 'isChild': isChild});

  @override
  Future<void> saveFood({
    required String householdId,
    required String memberId,
    required List<String> likes,
    required List<String> dislikes,
    required Set<DietaryFlag> diet,
  }) => _record('saveFood', {
    'memberId': memberId,
    'likes': likes,
    'dislikes': dislikes,
    'diet': diet,
  });

  @override
  Future<void> saveAllergy({
    required String householdId,
    required String memberId,
    required AllergyDraft draft,
    Allergy? replacing,
  }) => _record('saveAllergy', {
    'memberId': memberId,
    'draft': draft,
    'replacing': replacing,
  });

  @override
  Future<void> removeAllergy({
    required String householdId,
    required String memberId,
    required Allergy allergy,
  }) => _record('removeAllergy', {'memberId': memberId, 'allergy': allergy});

  @override
  Future<void> saveSchooling({
    required String householdId,
    required String memberId,
    String? schoolId,
    String? grade,
  }) => _record('saveSchooling', {
    'memberId': memberId,
    'schoolId': schoolId,
    'grade': grade,
  });

  @override
  Future<void> saveSizes({
    required String householdId,
    required String memberId,
    String? clothingSize,
    String? shoeSize,
  }) => _record('saveSizes', {
    'memberId': memberId,
    'clothingSize': clothingSize,
    'shoeSize': shoeSize,
  });

  @override
  Future<void> saveMedication({
    required String householdId,
    required String memberId,
    String? medicationId,
    required Medication medication,
  }) => _record('saveMedication', {
    'memberId': memberId,
    'medicationId': medicationId,
    'medication': medication,
  });

  @override
  Future<void> removeMedication({
    required String householdId,
    required String memberId,
    required String medicationId,
  }) => _record('removeMedication', {
    'memberId': memberId,
    'medicationId': medicationId,
  });

  var _schoolIds = 0;

  @override
  Future<String> addSchool({
    required String householdId,
    required String name,
    required bool nutFree,
  }) async {
    await _record('addSchool', {'name': name, 'nutFree': nutFree});
    _schoolIds += 1;
    return 'school-$_schoolIds';
  }

  @override
  Future<void> updateSchool({
    required String householdId,
    required String schoolId,
    required String name,
    required bool nutFree,
  }) => _record('updateSchool', {
    'schoolId': schoolId,
    'name': name,
    'nutFree': nutFree,
  });

  @override
  Future<void> deleteSchool({
    required String householdId,
    required String schoolId,
  }) => _record('deleteSchool', {'schoolId': schoolId});
}

/// The profiles every family test renders against: the kid with a severe
/// peanut allergy at a nut-free school, and nobody else filled in.
abstract final class FamilyFixtures {
  static const oakwood = School(
    id: 'oakwood',
    name: 'Oakwood Primary',
    nutFree: true,
  );

  static FamilyProfile get kid => const FamilyProfile(
    id: Fixtures.kidMemberId,
    isChild: true,
    likes: ['Pasta', 'Apples'],
    dislikes: ['Mushrooms'],
    diet: {DietaryFlag.halal},
    allergies: {
      Allergen.peanut: AllergyDetail(
        severity: AllergySeverity.severe,
        note: 'Adrenaline pen in her bag',
      ),
      Allergen.milk: AllergyDetail(severity: AllergySeverity.mild),
    },
    otherAllergies: {
      'k1': OtherAllergy(name: 'Kiwi', severity: AllergySeverity.moderate),
    },
    schoolId: 'oakwood',
    grade: 'Grade 3',
    clothingSize: '7–8',
    shoeSize: 'UK 13',
  );

  static const inhaler = Medication(
    name: 'Inhaler',
    dose: 'Two puffs',
    times: [1200, 420],
    note: 'Before sport too',
  );
}
