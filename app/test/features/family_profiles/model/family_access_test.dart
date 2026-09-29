import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/family_access.dart';
import 'package:nestprep/features/household/model/member_role.dart';

import '../../../support/household_fixtures.dart';

/// The client's mirror of `firestore.rules` for family profiles. The rules
/// suite proves the server; this proves the screen offers nothing it would
/// refuse, and hides medication from exactly the people the rules do
/// (family-profiles ADR-0001).
void main() {
  const kid = Fixtures.kidMemberId;

  test('an admin edits anybody and sees everybody"s medication', () {
    final access = FamilyAccess.of(Fixtures.view());
    expect(access.canEdit(kid), isTrue);
    expect(access.canSeeHealth(kid), isTrue);
    expect(access.canEditHealth(kid), isTrue);
    expect(access.canManageSchools, isTrue);
  });

  test('a member who is not an admin sees medication but changes only their '
      'own', () {
    const access = FamilyAccess(
      viewerRole: MemberRole.member,
      viewerMemberId: 'm-mia',
    );
    expect(access.canSeeHealth(kid), isTrue);
    expect(access.canEdit(kid), isFalse);
    expect(access.canEdit('m-mia'), isTrue);
    expect(access.canManageSchools, isFalse);
  });

  test('a helper does not see a child"s medication — the phase 2 seam', () {
    final access = FamilyAccess.of(
      Fixtures.view(viewerUid: Fixtures.thandiUid),
    );
    expect(access.canSeeHealth(kid), isFalse);
    expect(access.canEdit(kid), isFalse);
    expect(access.canEditHealth(kid), isFalse);
  });

  test('but sees and keeps their own', () {
    final access = FamilyAccess.of(
      Fixtures.view(viewerUid: Fixtures.thandiUid),
    );
    expect(access.canSeeHealth(Fixtures.thandiMemberId), isTrue);
    expect(access.canEdit(Fixtures.thandiMemberId), isTrue);
  });

  test('two readings of the same household are the same access', () {
    expect(FamilyAccess.of(Fixtures.view()), FamilyAccess.of(Fixtures.view()));
    expect(
      FamilyAccess.of(Fixtures.view()).hashCode,
      FamilyAccess.of(Fixtures.view()).hashCode,
    );
  });
}
