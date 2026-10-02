import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/family_route.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/family_profiles/model/member_health.dart';
import 'package:nestprep/features/family_profiles/state/family_controller.dart';
import 'package:nestprep/features/family_profiles/state/member_health_controller.dart';
import 'package:nestprep/features/family_profiles/ui/family_member_screen.dart';
import 'package:nestprep/features/family_profiles/ui/family_screen.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_family_profiles.dart';
import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// Family profiles are reached from More and open *over* it,
/// and a profile opens over the family — each with a way back, because a
/// capability with no way in is not done, and a pushed screen with no way back
/// closes the app (`FE-17`, the vault lesson on finished-but-unreachable).
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

  Future<void> pump(WidgetTester tester, String initialLocation) async {
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
    );
    households.emitHousehold(Fixtures.household());
    households.emitMembers([Fixtures.sam, Fixtures.thandi, Fixtures.kid]);
    repository.emitProfiles([FamilyFixtures.kid]);
    repository.emitSchools([FamilyFixtures.oakwood]);
    repository.emitHealth(MemberHealth.empty(Fixtures.kidMemberId));
    await tester.pumpAndSettle();
  }

  testWidgets('More is the way in', (tester) async {
    await pump(
      tester,
      HouseholdRoute.pathFor(Fixtures.householdId, HouseholdTab.more),
    );
    await tester.tap(find.text(FamilyCopy.openFromHousehold));
    await tester.pumpAndSettle();

    expect(find.text(FamilyCopy.children), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text(MoreCopy.subtitle), findsOneWidget);
  });

  testWidgets('a profile opens over the family, and back lands on it', (
    tester,
  ) async {
    await pump(tester, FamilyRoute.pathFor(Fixtures.householdId));
    await tester.tap(find.text('Kid Parker'));
    await tester.pumpAndSettle();

    expect(find.text(FamilyCopy.sectionAllergies), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
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
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
