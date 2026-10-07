import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/nanny_hub/model/nanny_access.dart';

import '../../../support/household_fixtures.dart';
import '../../../support/nanny_fixtures.dart';

/// The client's mirror of `nanny_hub.rules`: `view` reads, `edit` writes, and
/// what a card shows of allergies and medication is family profiles' grant
/// (nanny-hub ADR-0003). The rules tests are what prove the refusals; this
/// proves the app does not offer what they would refuse.
void main() {
  test('a carer on the carer defaults reads and writes the hub, and sees '
      'allergies and medication', () {
    final access = NannyAccess.of(NannyFixtures.carerView());
    expect(access.canView, isTrue);
    expect(access.canEdit, isTrue);
    expect(access.isFamily, isFalse);
    expect(access.canSeeAllergiesOf(Fixtures.kidMemberId), isTrue);
    expect(access.canSeeMedicationOf(Fixtures.kidMemberId), isTrue);
    expect(access.viewerMemberId, NannyFixtures.nomsaMemberId);
  });

  test('ends only their own shift', () {
    final access = NannyAccess.of(NannyFixtures.carerView());
    expect(access.mayEndShiftOf(NannyFixtures.nomsaMemberId), isTrue);
    expect(access.mayEndShiftOf(Fixtures.thandiMemberId), isFalse);
  });

  test('a carer narrowed to view reads and writes nothing', () {
    final access = NannyAccess.of(NannyFixtures.lookOnlyCarerView());
    expect(access.canView, isTrue);
    expect(access.canEdit, isFalse);
    expect(access.mayEndShiftOf(NannyFixtures.nomsaMemberId), isFalse);
  });

  test('a carer without the profile and medical grants sees neither', () {
    final access = NannyAccess.of(NannyFixtures.carerWithoutProfilesView());
    expect(access.canSeeAllergiesOf(Fixtures.kidMemberId), isFalse);
    expect(access.canSeeMedicationOf(Fixtures.kidMemberId), isFalse);
  });

  test('a helper on the helper defaults has no hub at all', () {
    final access = NannyAccess.of(Fixtures.helperView(AccessDefaults.helper));
    expect(access.canView, isFalse);
    expect(access.canEdit, isFalse);
  });

  test('family writes everything and ends anybody’s shift', () {
    final access = NannyAccess.of(NannyFixtures.parentView());
    expect(access.canEdit, isTrue);
    expect(access.isFamily, isTrue);
    expect(access.mayEndShiftOf(NannyFixtures.nomsaMemberId), isTrue);
  });

  test('two grants that differ in the hub are two answers', () {
    expect(
      NannyAccess.of(NannyFixtures.carerView()),
      NannyAccess.of(NannyFixtures.carerView()),
    );
    expect(
      NannyAccess.of(NannyFixtures.carerView()),
      isNot(NannyAccess.of(NannyFixtures.lookOnlyCarerView())),
    );
    final grant = AccessGrant.uniform(
      AccessLevel.none,
    ).withLevel(HouseholdArea.nannyHub, AccessLevel.edit);
    expect(NannyAccess.of(NannyFixtures.carerView(grant)).canEdit, isTrue);
  });
}
