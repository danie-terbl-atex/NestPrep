import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/account_menu_button.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/product_analytics/data/beta_numbers_repository.dart';
import 'package:nestprep/features/subscriptions/model/entitlement.dart';
import 'package:nestprep/features/subscriptions/state/household_entitlement.dart';
import 'package:nestprep/features/welcome_tour/model/tour_target.dart';
import 'package:nestprep/features/welcome_tour/state/tour_controller.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/fake_product_analytics.dart';
import '../../../support/fake_subscriptions.dart';
import '../../../support/household_fixtures.dart';

/// *Replay the tour* in the account menu (welcome-tour ADR-0002): any time,
/// seen or not, it starts the tour over the real screens — and only inside
/// a household, which is what the tour describes.
void main() {
  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;
  late FakeBetaNumbersRepository betaNumbers;

  setUp(() {
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
    betaNumbers = FakeBetaNumbersRepository();
  });

  tearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
    await betaNumbers.close();
  });

  /// Signed in as somebody who has seen the tour already.
  Future<void> signIn(WidgetTester tester) async {
    auth.emit(const AuthUser(uid: Fixtures.samUid, email: 'sam@nestprep.test'));
    // The session subscribes to the account only after `ensureAccount`, and
    // both fakes are broadcast streams: only real async gets it there.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    accounts.emit(
      const Account(
        id: Fixtures.samUid,
        displayName: 'Sam Parent',
        householdIds: [Fixtures.householdId],
        activeHouseholdId: Fixtures.householdId,
      ),
    );
    await tester.pumpAndSettle();
  }

  late TourController tour;

  Future<void> pump(WidgetTester tester, {required String initial}) {
    tour = TourController();
    addTearDown(tour.dispose);
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/households/:householdId/today',
          builder: (context, state) => MultiProvider(
            providers: [
              Provider<HouseholdView>.value(value: Fixtures.view()),
              ChangeNotifierProvider<TourController>.value(value: tour),
              ChangeNotifierProvider(
                create: (_) => testFlagsController(TestFlags.on),
              ),
              ChangeNotifierProvider<HouseholdEntitlement>(
                create: (_) => HouseholdEntitlement(
                  entitlementRepository: FakeEntitlementRepository(
                    initial: Entitlement.free,
                  ),
                  householdId: Fixtures.householdId,
                ),
              ),
            ],
            child: const Scaffold(body: Center(child: AccountMenuButton())),
          ),
        ),
        GoRoute(
          path: '/no-household',
          builder: (context, state) =>
              const Scaffold(body: Center(child: AccountMenuButton())),
        ),
      ],
    );
    addTearDown(router.dispose);
    return tester.pumpWidget(
      Provider<BetaNumbersRepository>.value(
        value: betaNumbers,
        child: ChangeNotifierProvider<SessionController>.value(
          value: session,
          child: MaterialApp.router(
            theme: nestThemeData(NestTheme.light()),
            routerConfig: router,
          ),
        ),
      ),
    );
  }

  testWidgets('starts the tour over the real screens, for somebody who saw '
      'it', (tester) async {
    await pump(tester, initial: '/households/h1/today');
    await signIn(tester);
    await tester.tap(find.bySemanticsLabel(AppCopy.account));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NestButton, TourCopy.replay));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.signOut), findsNothing, reason: 'sheet closed');
    expect(tour.isActive, isTrue);
    expect(tour.current?.target, TourTarget.tabBar);
    expect(tour.stops.last.target, TourTarget.accountMenu);
  });

  testWidgets('is not offered outside a household', (tester) async {
    await pump(tester, initial: '/no-household');
    await signIn(tester);
    await tester.tap(find.bySemanticsLabel(AppCopy.account));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.signOut), findsOneWidget);
    expect(find.text(TourCopy.replay), findsNothing);
  });
}
