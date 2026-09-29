import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/app/documents_route.dart';
import 'package:nestprep/app/family_route.dart';
import 'package:nestprep/app/household_place_redirect.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/app/lunch_route.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/household_area.dart';
import 'package:nestprep/features/household/model/household_view.dart';

import '../support/household_fixtures.dart';

/// Where somebody belongs inside a household once it has loaded (household
/// ADR-0003): into the invite step while a new household owes it, and away
/// from any place their grant does not open.
void main() {
  const id = Fixtures.householdId;

  HouseholdView view({
    String viewer = Fixtures.samUid,
    Map<String, String> members = const {
      Fixtures.samUid: 'admin',
      Fixtures.thandiUid: 'helper',
    },
    Map<String, AccessGrant> access = const {},
    String? pendingSetupStep,
  }) => HouseholdView(
    household: Household(
      id: id,
      name: 'The Parkers',
      timeZone: 'Africa/Johannesburg',
      members: members,
      access: access,
      pendingSetupStep: pendingSetupStep,
    ),
    members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
    viewerUid: viewer,
  );

  final week = HouseholdRoute.homeFor(id);
  final setup = HouseholdRoute.setupPathFor(id);

  group('the invite step', () {
    test('takes a new household’s admin there from wherever they land', () {
      expect(
        householdPlaceRedirect(
          location: week,
          view: view(pendingSetupStep: Household.invitePeopleStep),
        ),
        setup,
      );
    });

    test('leaves them there once they are', () {
      expect(
        householdPlaceRedirect(
          location: setup,
          view: view(pendingSetupStep: Household.invitePeopleStep),
        ),
        isNull,
      );
    });

    test('never stops anybody who is not an admin — they cannot invite', () {
      expect(
        householdPlaceRedirect(
          location: week,
          view: view(
            viewer: Fixtures.thandiUid,
            pendingSetupStep: Household.invitePeopleStep,
          ),
        ),
        isNull,
      );
      expect(
        householdPlaceRedirect(
          location: setup,
          view: view(viewer: Fixtures.thandiUid),
        ),
        week,
      );
    });

    test('is how an admin invites anybody later, once it is closed', () {
      expect(householdPlaceRedirect(location: setup, view: view()), isNull);
    });
  });

  group('a place a grant does not open', () {
    final cleaningOnly = {
      Fixtures.thandiUid: AccessGrant({
        HouseholdArea.homeCare: AccessLevel.own,
      }),
    };

    test('sends a helper who may only clean to the household screen', () {
      expect(
        householdPlaceRedirect(
          location: week,
          view: view(viewer: Fixtures.thandiUid, access: cleaningOnly),
        ),
        HouseholdRoute.householdPathFor(id),
      );
    });

    test('keeps them out of the documents', () {
      expect(
        householdPlaceRedirect(
          location: DocumentsRoute.folderPathFor(id, 'f-passports'),
          view: view(viewer: Fixtures.thandiUid, access: cleaningOnly),
        ),
        HouseholdRoute.householdPathFor(id),
      );
    });

    test('and out of family profiles, even by a deep link to one', () {
      expect(
        householdPlaceRedirect(
          location: FamilyRoute.memberPathFor(id, Fixtures.kidMemberId),
          view: view(viewer: Fixtures.thandiUid, access: cleaningOnly),
        ),
        HouseholdRoute.householdPathFor(id),
      );
    });

    test('sends somebody with groceries only to the groceries', () {
      expect(
        householdPlaceRedirect(
          location: week,
          view: view(
            viewer: Fixtures.thandiUid,
            access: {
              Fixtures.thandiUid: AccessGrant({
                HouseholdArea.groceries: AccessLevel.edit,
              }),
            },
          ),
        ),
        HouseholdRoute.pathFor(id, HouseholdTab.groceries),
      );
    });

    test('leaves the household screen alone — everybody can reach it', () {
      expect(
        householdPlaceRedirect(
          location: HouseholdRoute.householdPathFor(id),
          view: view(viewer: Fixtures.thandiUid, access: cleaningOnly),
        ),
        isNull,
      );
    });

    test('leaves family wherever they are', () {
      for (final tab in HouseholdTab.values) {
        expect(
          householdPlaceRedirect(
            location: HouseholdRoute.pathFor(id, tab),
            view: view(),
          ),
          isNull,
        );
      }
    });

    // lunch-box ADR-0004: lunch is home, and a grant without it moves on.
    test('opens a household on lunch, and a helper without lunch on the '
        'week', () {
      expect(HouseholdRoute.homeFor(id), LunchRoute.pathFor(id));
      expect(
        householdPlaceRedirect(
          location: HouseholdRoute.homeFor(id),
          view: view(
            viewer: Fixtures.thandiUid,
            access: {Fixtures.thandiUid: AccessDefaults.helper},
          ),
        ),
        HouseholdRoute.pathFor(id, HouseholdTab.week),
      );
    });

    test('keeps a grant without lunch out of its prep list and library', () {
      for (final location in [
        LunchRoute.prepPathFor(id),
        LunchRoute.libraryPathFor(id),
      ]) {
        expect(
          householdPlaceRedirect(
            location: location,
            view: view(viewer: Fixtures.thandiUid, access: cleaningOnly),
          ),
          HouseholdRoute.householdPathFor(id),
        );
      }
    });

    test('lets `own` through: a kid still has their chores', () {
      expect(
        householdPlaceRedirect(
          location: HouseholdRoute.pathFor(id, HouseholdTab.todos),
          view: view(
            viewer: Fixtures.thandiUid,
            members: const {
              Fixtures.samUid: 'admin',
              Fixtures.thandiUid: 'kid',
            },
            access: {
              Fixtures.thandiUid: AccessGrant({
                HouseholdArea.todos: AccessLevel.own,
              }),
            },
          ),
        ),
        isNull,
      );
    });
  });
}
