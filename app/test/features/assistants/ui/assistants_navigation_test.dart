import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nestprep/app/assistants_routes.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/assistants/data/assistant_repository.dart';
import 'package:nestprep/features/household/state/household_controller.dart';
import 'package:nestprep/features/household/ui/household_more_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/flags/feature_flag.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_assistants.dart';
import '../../../support/fake_auth.dart';
import '../../../support/fake_family_profiles.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_household.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

/// *Connected assistants* is reachable from More while its switch is on, and
/// only then, and back comes back (`FE-17`, assistants ADR-0001) — a
/// capability with no way in is not done (the vault lesson).
void main() {
  late FakeAssistantRepository assistants;
  late FakeFeatureFlagSource flags;

  Future<void> pumpMore(
    WidgetTester tester, {
    String viewerUid = Fixtures.samUid,
    bool isOn = true,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = const Size(420 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    assistants = FakeAssistantRepository();
    flags = FakeFeatureFlagSource();
    final auth = FakeAuthGateway();
    final accounts = FakeAccountRepository();
    final session = SessionController(
      authGateway: auth,
      accountRepository: accounts,
    );
    auth.emit(AuthUser(uid: viewerUid, email: 'member@nestprep.test'));
    final households = FakeHouseholdRepository();
    final controller = HouseholdController(
      householdRepository: households,
      householdDirectory: FakeHouseholdDirectory(),
      childProfileDirectory: FakeFamilyProfileRepository(),
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
    );
    addTearDown(() async {
      controller.dispose();
      session.dispose();
      await households.close();
      await assistants.close();
      await flags.close();
      await auth.close();
      await accounts.close();
    });
    await pumpRouter(
      tester,
      router: GoRouter(
        initialLocation: HouseholdRoute.pathFor(
          Fixtures.householdId,
          HouseholdTab.more,
        ),
        routes: [
          GoRoute(
            path: '${HouseholdRoute.path}/${HouseholdTab.more.segment}',
            builder: (context, state) =>
                HouseholdMoreScreen(onSelectTab: (_) {}),
          ),
          assistantsRoute(session),
        ],
      ),
      view: Fixtures.view(viewerUid: viewerUid),
      brightness: brightness,
      providers: [
        ChangeNotifierProvider<HouseholdController>.value(value: controller),
        Provider<AssistantRepository>.value(value: assistants),
        featureFlagsProvider(source: flags),
      ],
    );
    flags.emit({FeatureFlag.assistants.field: isOn});
    households.emitHousehold(Fixtures.household());
    households.emitMembers([Fixtures.sam, Fixtures.thandi, Fixtures.kid]);
    await tester.pumpAndSettle();
    // The session listens for the account once it has seen the sign-in, so
    // the account comes after.
    accounts.emit(
      Account(
        id: viewerUid,
        displayName: 'A member',
        householdIds: const [Fixtures.householdId],
        activeHouseholdId: Fixtures.householdId,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets('More is a way in, and back comes back (${brightness.name})', (
      tester,
    ) async {
      await pumpMore(tester, brightness: brightness);
      expect(find.text(AssistantsCopy.sectionMore), findsOneWidget);
      await tester.tap(find.text(AssistantsCopy.title));
      await tester.pump();
      // The skeleton pulses for as long as it shows, so it gets an answer
      // before anything settles.
      assistants.emitConnections([]);
      await tester.pumpAndSettle();
      expect(find.text(AssistantsCopy.subtitle), findsOneWidget);
      expect(find.text(AssistantsCopy.emptyTitle), findsOneWidget);
      expect(assistants.connectionOwners, [null]);

      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();
      expect(find.text(MoreCopy.subtitle), findsOneWidget);
    });

    testWidgets('nobody is offered it while it is switched off '
        '(${brightness.name})', (tester) async {
      await pumpMore(tester, isOn: false, brightness: brightness);
      expect(find.text(AssistantsCopy.title), findsNothing);
      expect(find.text(AssistantsCopy.sectionMore), findsNothing);
    });
  }

  testWidgets('somebody who is not family is offered it, and reads only '
      'their own', (tester) async {
    await pumpMore(tester, viewerUid: Fixtures.thandiUid);
    await tester.tap(find.text(AssistantsCopy.title));
    await tester.pump();
    assistants.emitConnections([]);
    await tester.pumpAndSettle();
    expect(find.text(AssistantsCopy.emptyBodyForOthers), findsOneWidget);
    expect(assistants.connectionOwners, [Fixtures.thandiUid]);
    expect(assistants.activityMembers, [Fixtures.thandiMemberId]);
  });
}
