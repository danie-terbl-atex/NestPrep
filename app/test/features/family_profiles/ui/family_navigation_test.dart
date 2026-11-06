import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nestprep/app/family_route.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/family_profiles/state/member_health_controller.dart';
import 'package:nestprep/features/family_profiles/ui/family_member_screen.dart';
import 'package:nestprep/features/family_profiles/ui/family_screen.dart';
import 'package:nestprep/features/household/model/access_grant.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:nestprep/features/household/ui/household_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Family profiles are People's Profiles tab, reached from More's People card
/// and opening *over* More (design-system ADR-0022), and a profile opens over
/// the family — each with a way back, because a capability with no way in is
/// not done, and a pushed screen with no way back closes the app (`FE-17`, the
/// vault lesson on finished-but-unreachable).
void main() {
  late FakeFamilyProfileRepository repository;
  late FakeHouseholdRepository households;
  late FamilyController family;
  late MemberHealthController health;
  late HouseholdController householdController;

  setUp(() {
    repository = FakeFamilyProfileRepository();
    households = FakeHouseholdRepository();
    family = FamilyController(
      familyProfileRepository: repository,
      childProfileDirectory: repository,
      householdId: Fixtures.householdId,
      household: Fixtures.view(),
    );
    health = MemberHealthController(
      familyProfileRepository: repository,
      householdId: Fixtures.householdId,
      memberId: Fixtures.kidMemberId,
      isVisible: true,
    );
    householdController = HouseholdController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      childProfileDirectory: FakeFamilyProfileRepository(),
      householdId: Fixtures.householdId,
      viewerUid: Fixtures.samUid,
    );
  });

  tearDown(() async {
    family.dispose();
    health.dispose();
    householdController.dispose();
    await repository.close();
    await households.close();
  });

  Future<void> pump(
    WidgetTester tester,
    String initialLocation, {
    HouseholdView? view,
  }) async {
    tester.view.physicalSize = const Size(420 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '${HouseholdRoute.path}/${HouseholdTab.more.segment}',
            builder: (context, state) =>
                HouseholdMoreScreen(onSelectTab: (_) {}),
          ),
          GoRoute(
            path: '${HouseholdRoute.path}/${HouseholdRoute.householdSegment}',
            builder: (context, state) => const HouseholdScreen(),
          ),
          GoRoute(
            path: FamilyRoute.path,
            builder: (context, state) => const FamilyScreen(),
          ),
          GoRoute(
            path: FamilyRoute.memberPath,
            builder: (context, state) =>
                FamilyMemberScreen(memberId: FamilyRoute.memberIdFrom(state)),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<HouseholdController>.value(
          value: householdController,
        ),
        ChangeNotifierProvider<FamilyController>.value(value: family),
        ChangeNotifierProvider<MemberHealthController>.value(value: health),
      ],
      view: view,
    );
    households.emitHousehold(Fixtures.household());
    households.emitMembers([Fixtures.sam, Fixtures.thandi, Fixtures.kid]);
    repository.emitProfiles([FamilyFixtures.kid]);
    repository.emitSchools([FamilyFixtures.oakwood]);
    repository.emitHealth(MemberHealth.empty(Fixtures.kidMemberId));
    await tester.pumpAndSettle();
  }

  testWidgets('More is the way in: People, then its Profiles tab', (
    tester,
  ) async {
    await pump(
      tester,
      HouseholdRoute.pathFor(Fixtures.householdId, HouseholdTab.more),
    );
    expect(find.text(FamilyCopy.openFromHousehold), findsNothing);
    await tester.tap(find.text(MoreCopy.peopleTitle));
    await tester.pumpAndSettle();
    expect(find.byType(HouseholdScreen), findsOneWidget);

    await tester.tap(find.text(MoreCopy.peopleProfiles));
    await tester.pumpAndSettle();
    expect(find.text(FamilyCopy.children), findsOneWidget);
    expect(find.byType(HouseholdScreen), findsNothing);

    await tester.tap(find.text(MoreCopy.peopleHousehold));
    await tester.pumpAndSettle();
    expect(find.byType(HouseholdScreen), findsOneWidget);

    await tester.tap(find.text(MoreCopy.peopleProfiles));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.text(MoreCopy.subtitle), findsOneWidget);
    expect(find.byType(FamilyScreen), findsNothing);
    expect(find.byType(HouseholdScreen), findsNothing);
  });

  testWidgets('without the profiles grant, People has no tabs', (tester) async {
    await pump(
      tester,
      HouseholdRoute.householdPathFor(Fixtures.householdId),
      view: Fixtures.helperView(AccessGrant.uniform(AccessLevel.none)),
    );
    expect(find.byType(HouseholdScreen), findsOneWidget);
    expect(find.text(MoreCopy.peopleProfiles), findsNothing);
  });

  testWidgets('a profile opens over the family, and back lands on it', (
    tester,
  ) async {
    await pump(tester, FamilyRoute.pathFor(Fixtures.householdId));
    await tester.tap(find.text('Kid Parker'));
    await tester.pumpAndSettle();

    expect(find.text(FamilyCopy.sectionAllergies), findsOneWidget);
    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.text(FamilyCopy.children), findsOneWidget);
    expect(find.text(FamilyCopy.sectionAllergies), findsNothing);
  });

  testWidgets('a deep link straight to a profile offers no way back', (
    tester,
  ) async {
    await pump(
      tester,
      FamilyRoute.memberPathFor(Fixtures.householdId, Fixtures.kidMemberId),
    );
    expect(find.text(FamilyCopy.sectionAllergies), findsOneWidget);
    expect(find.byIcon(LucideIcons.arrowLeft), findsNothing);
  });
}
