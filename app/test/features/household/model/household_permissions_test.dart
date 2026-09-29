import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_permissions.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/household/model/member_role.dart';

/// The client's copy of the rules' `canView`, `canEdit` and `hasOwnOnly`
/// (household ADR-0003). It decides nothing — the rules suite proves what is
/// refused — but a screen that shows a helper a button the server refuses is
/// the bug this exists to prevent, so every case the rules draw is drawn here
/// too, from the same household the rules suite uses.
void main() {
  final cleaningOnly = AccessGrant({HouseholdArea.homeCare: AccessLevel.own});

  Household household({
    Map<String, String> members = const {},
    Map<String, AccessGrant> access = const {},
    Map<String, String> profiles = const {},
  }) => Household(
    id: 'h1',
    name: 'The Parkers',
    timeZone: 'Africa/Johannesburg',
    members: members,
    access: access,
    profiles: profiles,
  );

  HouseholdPermissions of(Household household, String uid) =>
      HouseholdPermissions.of(household, uid);

  group('family', () {
    for (final role in ['admin', 'parent', 'member']) {
      test('$role uses every area, and changes everything in it', () {
        final permissions = of(household(members: {'u': role}), 'u');
        for (final area in HouseholdArea.values) {
          expect(permissions.canEdit(area), isTrue, reason: area.key);
          expect(permissions.canView(area), isTrue, reason: area.key);
        }
        expect(permissions.isFamily, isTrue);
      });
    }

    test(
      'a grant left over on a family member is ignored, as the rules do',
      () {
        final permissions = of(
          household(members: {'u': 'parent'}, access: {'u': cleaningOnly}),
          'u',
        );
        expect(permissions.canEdit(HouseholdArea.documents), isTrue);
        expect(permissions.grant, isNull);
      },
    );
  });

  group('a helper who may only clean', () {
    final permissions = of(
      household(
        members: {'u': 'helper'},
        access: {'u': cleaningOnly},
        profiles: {'u': 'm-thandi'},
      ),
      'u',
    );

    test('sees home care as their own, and nothing else', () {
      expect(permissions.hasOwnOnly(HouseholdArea.homeCare), isTrue);
      expect(permissions.canView(HouseholdArea.homeCare), isFalse);
      for (final area in HouseholdArea.values) {
        if (area == HouseholdArea.homeCare) continue;
        expect(permissions.canUse(area), isFalse, reason: area.key);
      }
    });

    test('knows which profile "own" means', () {
      expect(permissions.ownMemberId, 'm-thandi');
    });
  });

  group('the levels, one by one', () {
    HouseholdPermissions withGrocery(AccessLevel level) => of(
      household(
        members: {'u': 'carer'},
        access: {
          'u': AccessGrant({HouseholdArea.groceries: level}),
        },
      ),
      'u',
    );

    test('view reads and does not change', () {
      final permissions = withGrocery(AccessLevel.view);
      expect(permissions.canView(HouseholdArea.groceries), isTrue);
      expect(permissions.canEdit(HouseholdArea.groceries), isFalse);
    });

    test('edit does both', () {
      final permissions = withGrocery(AccessLevel.edit);
      expect(permissions.canEdit(HouseholdArea.groceries), isTrue);
    });

    test('none is not there at all', () {
      expect(
        withGrocery(AccessLevel.none).canUse(HouseholdArea.groceries),
        isFalse,
      );
    });

    test('own on an area that has no "own" is none, never more', () {
      expect(
        withGrocery(AccessLevel.own).canUse(HouseholdArea.groceries),
        isFalse,
      );
    });
  });

  group('somebody with no grant recorded', () {
    test('a helper claimed before ADR-0003 keeps everything', () {
      final permissions = of(household(members: {'u': 'helper'}), 'u');
      for (final area in HouseholdArea.values) {
        expect(permissions.canEdit(area), isTrue, reason: area.key);
      }
    });

    for (final role in ['kid', 'carer']) {
      test('a $role has nothing — deny by default for the new roles', () {
        final permissions = of(household(members: {'u': role}), 'u');
        for (final area in HouseholdArea.values) {
          expect(permissions.canUse(area), isFalse, reason: area.key);
        }
      });
    }

    test('an account not in the household has nothing at all', () {
      final permissions = of(household(members: {'u': 'admin'}), 'stranger');
      expect(permissions.isMember, isFalse);
      expect(permissions.canUse(HouseholdArea.calendar), isFalse);
    });
  });

  group('a profile nobody has claimed yet', () {
    Member profile(String role, {AccessGrant? access}) => Member(
      id: 'm-new',
      displayName: 'Grace',
      color: MemberColor.mint,
      roleName: role,
      access: access,
    );

    test('holds its own stored choice', () {
      final permissions = HouseholdPermissions.unclaimed(
        profile('helper', access: cleaningOnly),
      );
      expect(permissions.grant, cleaningOnly);
    });

    test("or its role's defaults, which is what redeeming it records", () {
      expect(
        HouseholdPermissions.unclaimed(profile('carer')).grant,
        AccessDefaults.carer,
      );
      expect(
        HouseholdPermissions.unclaimed(profile('kid')).grant,
        AccessDefaults.kid,
      );
    });
  });

  group('roles read from storage', () {
    test('`member` is a parent, and nothing is taken from it', () {
      expect(MemberRole.fromName('member'), MemberRole.parent);
    });

    test('a role this build has never heard of is restricted, not family', () {
      final role = MemberRole.fromName('superhero');
      expect(role.isFamily, isFalse);
    });
  });
}
