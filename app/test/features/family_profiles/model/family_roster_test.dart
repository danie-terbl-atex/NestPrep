import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/family_profile.dart';
import 'package:nestprep/features/family_profiles/model/family_roster.dart';
import 'package:nestprep/features/family_profiles/model/school.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/household_fixtures.dart';

/// The read other features consume: household's members joined with this
/// feature's profiles and schools, once.
void main() {
  FamilyRoster roster({
    List<FamilyProfile>? profiles,
    List<School> schools = const [FamilyFixtures.oakwood],
  }) => FamilyRoster(
    members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    profiles: profiles ?? [FamilyFixtures.kid],
    schools: schools,
  );

  test('everybody on the member list has an entry, profile or not', () {
    final family = roster();
    expect(family.entries.map((entry) => entry.memberId), [
      Fixtures.samMemberId,
      Fixtures.thandiMemberId,
      Fixtures.kidMemberId,
    ]);
    expect(
      family.entryFor(Fixtures.samMemberId)!.profile,
      FamilyProfile.empty(Fixtures.samMemberId),
    );
  });

  test('children are the profiles a parent marked, and the free tier counts '
      'them', () {
    final family = roster();
    expect(family.children.map((entry) => entry.memberId), [
      Fixtures.kidMemberId,
    ]);
    expect(family.everyoneElse, hasLength(2));
    expect(family.childCount, 1);
  });

  test('a child"s school and its rule arrive with them', () {
    final kid = roster().entryFor(Fixtures.kidMemberId)!;
    expect(kid.school, FamilyFixtures.oakwood);
    expect(kid.foodRules.isNutFree, isTrue);
  });

  test('a deleted school reads as no school, not as a failure', () {
    final kid = roster(schools: const []).entryFor(Fixtures.kidMemberId)!;
    expect(kid.school, isNull);
    expect(kid.profile.schoolId, 'oakwood', reason: 'the pointer is kept');
  });

  test('a profile whose member has gone is dropped', () {
    final family = roster(
      profiles: [FamilyFixtures.kid, FamilyProfile.empty('m-gone')],
    );
    expect(family.entryFor('m-gone'), isNull);
    expect(family.entries, hasLength(3));
  });

  test('schools are by name, and know how many are at each', () {
    final family = roster(
      schools: const [
        School(id: 'z', name: 'Zenith'),
        FamilyFixtures.oakwood,
      ],
    );
    expect(family.schools.map((school) => school.name), [
      'Oakwood Primary',
      'Zenith',
    ]);
    expect(family.pupilsAt('oakwood'), 1);
    expect(family.pupilsAt('z'), 0);
    expect(family.schoolById('z')?.name, 'Zenith');
  });
}
