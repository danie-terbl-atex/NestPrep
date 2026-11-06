import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/app/household_route.dart';
import 'package:nestprep/app/household_shell.dart';
import 'package:nestprep/app/shops_route.dart';
import 'package:nestprep/features/account_data/ui/account_centre_screen.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/shared/copy/shops_copy.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_feature_flag_source.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_screen.dart';

void main() {
  late FakeAuthGateway auth;
  late FakeAccountRepository accounts;
  late SessionController session;

  setUp(() {
    auth = FakeAuthGateway();
    accounts = FakeAccountRepository();
    session = SessionController(authGateway: auth, accountRepository: accounts);
  });

  tearDown(() async {
    session.dispose();
    await auth.close();
    await accounts.close();
  });

  Future<void> pumpSignedIn(
    WidgetTester tester, {
    List<SingleChildWidget> providers = const [],
    Brightness brightness = Brightness.light,
    double scale = 1,
    GoRouter? router,
  }) async {
    await pumpRouter(
      tester,
      router:
          router ??
          GoRouter(
            initialLocation: AccountCentreScreen.path,
            routes: [
              GoRoute(
                path: AccountCentreScreen.path,
                builder: (_, _) => const AccountCentreScreen(),
              ),
              GoRoute(
                path: ShopsRoute.path,
                builder: (_, state) => Text('page ${state.uri.path}'),
              ),
            ],
          ),
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        ...providers,
      ],
      brightness: brightness,
      textScale: scale,
    );
    auth.emit(const AuthUser(uid: Fixtures.samUid, email: 'sam@nestprep.test'));
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

  Future<void> bringIntoView(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the account centre opens Your shops for the household', (
    tester,
  ) async {
    await pumpSignedIn(tester);
    final entry = find.text(ShopsCopy.entry);
    await bringIntoView(tester, entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(
      find.text('page ${ShopsRoute.pathFor(Fixtures.householdId)}'),
      findsOneWidget,
    );
  });

  testWidgets(
    'opened over the household, Your shops opens in that household and back '
    'returns to it',
    (tester) async {
      final todosPath = HouseholdRoute.pathFor(
        Fixtures.householdId,
        HouseholdTab.todos,
      );
      final router = GoRouter(
        initialLocation: todosPath,
        routes: [
          GoRoute(
            path: AccountCentreScreen.path,
            builder: (_, _) => const AccountCentreScreen(),
          ),
          ShellRoute(
            builder: (_, _, child) => child,
            routes: [
              GoRoute(
                path: '${HouseholdRoute.path}/${HouseholdTab.todos.segment}',
                builder: (_, _) => const Text('the household'),
              ),
              GoRoute(
                path: ShopsRoute.path,
                builder: (context, state) => Scaffold(
                  body: Column(
                    children: [
                      Text('page ${state.uri.path}'),
                      TextButton(
                        onPressed: context.pop,
                        child: const Text('back'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpSignedIn(tester, router: router);
      unawaited(router.push(AccountCentreScreen.path));
      await tester.pumpAndSettle();

      final entry = find.text(ShopsCopy.entry);
      await bringIntoView(tester, entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('page ${ShopsRoute.pathFor(Fixtures.householdId)}'),
        findsOneWidget,
      );
      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();
      expect(find.text('the household'), findsOneWidget);
    },
  );

  testWidgets('with every shop switched off there is no way in', (
    tester,
  ) async {
    await pumpSignedIn(
      tester,
      providers: [featureFlagsProvider(defaultOn: false)],
    );
    expect(find.text('Sam Parent'), findsOneWidget);
    expect(find.text(ShopsCopy.entry), findsNothing);
    expect(find.text(ShopsCopy.centreSection), findsNothing);
  });

  testWidgets('the way in survives dark at 200% text on a 360-wide phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpSignedIn(tester, brightness: Brightness.dark, scale: 2);
    await bringIntoView(tester, find.text(ShopsCopy.entryHint));
    expect(tester.takeException(), isNull);
  });
}
