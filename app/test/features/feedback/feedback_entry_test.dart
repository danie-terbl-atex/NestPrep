import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/account_data/ui/account_centre_screen.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/account_menu_button.dart';
import 'package:nestprep/features/feedback/ui/feedback_screen.dart';
import 'package:nestprep/features/product_analytics/data/beta_numbers_repository.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../support/fake_auth.dart';
import '../../support/fake_product_analytics.dart';
import '../../support/household_fixtures.dart';

/// The two ways in (feedback ADR-0001): the account sheet, which records the
/// route pattern of the screen behind it, and the account centre's row.
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

  Future<void> pumpAt(WidgetTester tester, String location) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/households/:householdId/lunch',
          builder: (_, _) =>
              const Scaffold(body: Center(child: AccountMenuButton())),
        ),
        GoRoute(
          path: AccountCentreScreen.path,
          builder: (_, _) => const AccountCentreScreen(),
        ),
        GoRoute(
          path: FeedbackScreen.path,
          builder: (_, state) => Text(
            'feedback from '
            '${state.uri.queryParameters[FeedbackScreen.fromParameter]}',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
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

  testWidgets('the account sheet opens it with the pattern, never the ids', (
    tester,
  ) async {
    await pumpAt(tester, '/households/${Fixtures.householdId}/lunch');

    await tester.tap(find.bySemanticsLabel(AppCopy.account));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('account-send-feedback')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-send-feedback')));
    await tester.pumpAndSettle();

    expect(
      find.text('feedback from /households/:householdId/lunch'),
      findsOneWidget,
    );
    expect(find.textContaining(Fixtures.householdId), findsNothing);
  });

  testWidgets('the account centre lists it beside About', (tester) async {
    await pumpAt(tester, AccountCentreScreen.path);

    final row = find.text(FeedbackCopy.entry);
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('feedback from null'), findsOneWidget);
  });
}
