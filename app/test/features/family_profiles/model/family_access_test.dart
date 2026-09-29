import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/family_access.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';

import '../../../support/household_fixtures.dart';

/// The client's mirror of the family-profiles rules. The rules suite proves
/// the server; this proves the screen offers nothing it would refuse, and
/// shows profiles and medication to exactly the people the household's grant
/// does (family-profiles ADR-0002, household ADR-0003).
void main() {
  const kid = Fixtures.kidMemberId;
  const thandi = Fixtures.thandiMemberId;

  FamilyAccess helperWith(Map<HouseholdArea, AccessLevel> levels) =>
      FamilyAccess.of(
        Fixtures.helperView(
          levels.entries.fold(
            AccessGrant.uniform(AccessLevel.none),
            (grant, entry) => grant.withLevel(entry.key, entry.value),
          ),
        ),
      );

  test('an admin sees and edits everybody, medication and schools too', () {
    final access = FamilyAccess.of(Fixtures.view());
    expect(access.isVisible, isTrue);
    expect(access.seesEveryProfile, isTrue);
    expect(access.canEdit(kid), isTrue);
    expect(access.canSeeHealth(kid), isTrue);
    expect(access.canEditHealth(kid), isTrue);
    expect(access.canManageSchools, isTrue);
  });

  test('a helper on the defaults does not have family profiles at all', () {
    final access = FamilyAccess.of(Fixtures.helperView(AccessDefaults.helper));
    expect(access.isVisible, isFalse);
    expect(access.canSeeProfile(kid), isFalse);
    expect(access.canSeeHealth(kid), isFalse);
  });

  test('a carer on the defaults sees every profile and the medication, and '
      'edits nobody else', () {
    final access = FamilyAccess.of(Fixtures.helperView(AccessDefaults.carer));
    expect(access.seesEveryProfile, isTrue);
    expect(access.canSeeHealth(kid), isTrue);
    expect(access.canEdit(kid), isFalse);
    expect(access.canManageSchools, isFalse);
  });

  test('profiles at view without medical: the allergies, not the medicine', () {
    final access = helperWith({HouseholdArea.familyProfiles: AccessLevel.view});
    expect(access.canSeeProfile(kid), isTrue);
    expect(access.canSeeHealth(kid), isFalse);
  });

  test('`own` sees their own profile only, and reads only that', () {
    final access = helperWith({
      HouseholdArea.familyProfiles: AccessLevel.own,
      HouseholdArea.medical: AccessLevel.own,
    });
    expect(access.isVisible, isTrue);
    expect(access.seesEveryProfile, isFalse);
    expect(access.ownMemberId, thandi);
    expect(access.canSeeProfile(kid), isFalse);
    expect(access.canSeeHealth(kid), isFalse);
    expect(access.canSeeProfile(thandi), isTrue);
  });

  test('a person always sees and keeps their own, whatever the grant', () {
    final access = helperWith(const {});
    expect(access.canSeeHealth(thandi), isTrue);
    expect(access.canEdit(thandi), isTrue);
    expect(access.canEdit(kid), isFalse);
  });

  test('two readings of the same household are the same access', () {
    expect(FamilyAccess.of(Fixtures.view()), FamilyAccess.of(Fixtures.view()));
    expect(
      FamilyAccess.of(Fixtures.view()).hashCode,
      FamilyAccess.of(Fixtures.view()).hashCode,
    );
    expect(
      FamilyAccess.of(Fixtures.view()),
      isNot(FamilyAccess.of(Fixtures.helperView(AccessDefaults.carer))),
    );
  });
}
