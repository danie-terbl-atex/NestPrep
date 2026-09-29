import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/account_menu_button.dart';
import 'package:nestprep/features/product_analytics/data/beta_numbers_repository.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_product_analytics.dart';
import '../../../support/household_fixtures.dart';

/// The button in the corner of every screen, and the only way out of the app.
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

  Future<void> signIn(WidgetTester tester) async {
    auth.emit(const AuthUser(uid: Fixtures.samUid, email: 'sam@nestprep.test'));
    // The controller only subscribes to the account document after
    // `ensureAccount` resolves, and both fakes are broadcast streams — an
    // account emitted before that subscription exists is simply dropped.
    // Pumping frames cannot advance a Future; only real async can.
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

  /// The repository sits above the app, as it does in the real one: the sheet
  /// is a route on the root navigator and sees nothing provided below it.
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    Provider<BetaNumbersRepository>.value(
      value: betaNumbers,
      child: ChangeNotifierProvider<SessionController>.value(
        value: session,
        child: MaterialApp(
          theme: nestThemeData(NestTheme.light()),
          home: const Scaffold(body: Center(child: AccountMenuButton())),
        ),
      ),
    ),
  );

  testWidgets('says nothing until somebody is signed in', (tester) async {
    await pump(tester);
    await tester.tap(find.bySemanticsLabel(AppCopy.account));
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.signOut),
      findsNothing,
      reason: 'there is nobody to sign out yet',
    );
  });

  testWidgets('shows who is signed in, by name and by email', (tester) async {
    await pump(tester);
    await signIn(tester);

    await tester.tap(find.bySemanticsLabel(AppCopy.account));
    await tester.pumpAndSettle();

    expect(find.text('Sam Parent'), findsOneWidget);
    expect(find.text('sam@nestprep.test'), findsOneWidget);
  });

  testWidgets('signing out closes the sheet and signs out once', (
    tester,
  ) async {
    await pump(tester);
    await signIn(tester);

    await tester.tap(find.bySemanticsLabel(AppCopy.account));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NestButton, AppCopy.signOut));
    await tester.pumpAndSettle();

    expect(auth.signOutCount, 1);
    expect(
      find.text(AppCopy.signOut),
      findsNothing,
      reason: 'the sheet closes before the screen behind it changes',
    );
  });

  testWidgets('offers the Beta numbers only to an account holding the claim', (
    tester,
  ) async {
    await pump(tester);
    await signIn(tester);
    await tester.tap(find.bySemanticsLabel(AppCopy.account));
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.productAnalytics.openLink), findsNothing);
  });

  testWidgets('and to a reader, beside signing out', (tester) async {
    betaNumbers.isReader = true;
    await pump(tester);
    await signIn(tester);
    await tester.tap(find.bySemanticsLabel(AppCopy.account));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(NestButton, AppCopy.productAnalytics.openLink),
      findsOneWidget,
    );
    expect(find.widgetWithText(NestButton, AppCopy.signOut), findsOneWidget);
  });
}
