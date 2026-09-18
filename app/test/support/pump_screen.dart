import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'fake_auth.dart';
import 'household_fixtures.dart';

/// Pumps a feature screen the way its route does: the household and its clock
/// above it, its controller beside it, and a router under it so a header link
/// has somewhere to go (`FE-17`).
///
/// [router] replaces the one-screen router for a test whose subject *is* the
/// navigation — whether a row pushes or replaces, and whether the screen it
/// opens can be come back from. [screen] is then unused, because the router
/// builds its own. Everything above the router is the same either way, which is
/// the reason this takes a router rather than a second helper growing its own
/// copy of the session (`ENG-01`).
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required List<SingleChildWidget> providers,
  HouseholdView? view,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  GoRouter? router,
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
        ...providers,
      ],
      child: MaterialApp.router(
        // Nothing asserts on it, and it sits on top of the top-right corner of
        // every screenshot the design review takes.
        debugShowCheckedModeBanner: false,
        theme: nestThemeData(nest),
        routerConfig:
            router ??
            GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(textScale)),
                    child: screen,
                  ),
                ),
                GoRoute(
                  path: '/households/:householdId/household',
                  builder: (context, state) => const Placeholder(),
                ),
                GoRoute(
                  path: '/households/:householdId/where',
                  builder: (context, state) => const Placeholder(),
                ),
              ],
            ),
      ),
    ),
  );
}
