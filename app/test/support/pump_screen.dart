import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'fake_auth.dart';
import 'household_fixtures.dart';

/// Pumps a feature screen the way its route does: the household and its clock
/// above it, its controller beside it, and a router under it so a header link
/// has somewhere to go (`FE-17`).
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required List<SingleChildWidget> providers,
  HouseholdView? view,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) => pumpRouter(
  tester,
  router: GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => screen),
      GoRoute(
        path: '/households/:householdId/household',
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/households/:householdId/where',
        builder: (context, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/households/:householdId/kids',
        builder: (context, state) => const Placeholder(),
      ),
    ],
  ),
  providers: providers,
  view: view,
  brightness: brightness,
  textScale: textScale,
);

/// The same scaffolding, for a test that needs its own route table — pushing
/// one screen over another, and proving there is somewhere to go back to
/// (`FE-17`). `pumpScreen` is this with a one-screen router.
Future<void> pumpRouter(
  WidgetTester tester, {
  required GoRouter router,
  required List<SingleChildWidget> providers,
  HouseholdView? view,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) {
  tz_data.initializeTimeZones();
  final householdView = view ?? Fixtures.view();
  // Every feature header carries the account button, so a screen test needs a
  // session above it exactly as the running app does.
  final auth = FakeAuthGateway();
  final accounts = FakeAccountRepository();
  final session = SessionController(
    authGateway: auth,
    accountRepository: accounts,
  );
  auth.emit(const AuthUser(uid: Fixtures.samUid, email: 'sam@nestprep.test'));
  accounts.emit(
    const Account(
      id: Fixtures.samUid,
      displayName: 'Sam Parent',
      householdIds: [Fixtures.householdId],
      activeHouseholdId: Fixtures.householdId,
    ),
  );
  addTearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
  });
  final nest = brightness == Brightness.dark
      ? NestTheme.dark()
      : NestTheme.light();

  return tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        Provider<HouseholdView>.value(value: householdView),
        Provider<HouseholdClock>.value(
          value: HouseholdClock(householdView.household.timeZone),
        ),
        // Every V2 way in shows, as in a debug build; a test of a switched-off
        // capability passes its own (foundation ADR-0014).
        Provider<FeatureFlags>.value(value: FeatureFlags.everythingOn),
        ...providers,
      ],
      child: MaterialApp.router(
        // Nothing asserts on it, and it sits on top of the top-right corner of
        // every screenshot the design review takes.
        debugShowCheckedModeBanner: false,
        theme: nestThemeData(nest),
        routerConfig: router,
        // Above the router rather than inside one route's builder, so every
        // screen a test pushes is scaled, not only the first.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
