import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/account_menu_button.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_kit.dart';

/// The button in the corner of every screen, and the only way out of the app.
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

  Future<void> pump(WidgetTester tester) => pumpKit(
    tester,
    ChangeNotifierProvider<SessionController>.value(
      value: session,
      child: const AccountMenuButton(),
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
}
