import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/model/account.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/verify_email_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/household_fixtures.dart';
import '../../../support/pump_kit.dart';

/// Where somebody waits with an account and an address nobody has proved
/// (accounts ADR-0002).
///
/// The screen is the explanation, never the enforcement — the callables refuse
/// an unverified caller whatever this renders — so what matters here is that it
/// can always be left: by proving the address, by asking for another email, or
/// by signing out because the address was a typo.
void main() {
  const email = 'sam@nestprep.test';

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

  /// Drives the controller to signed in with an unverified address.
  ///
  /// The two emits cannot be back to back: the controller subscribes to the
  /// account document only after `ensureAccount` resolves, and both fakes are
  /// broadcast streams, so an account emitted before that subscription exists
  /// is dropped. Pumping frames cannot advance a Future; only real async can.
  Future<void> signIn(WidgetTester tester) async {
    auth.emit(const AuthUser(uid: Fixtures.samUid, email: email));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    accounts.emit(
      const Account(id: Fixtures.samUid, displayName: 'Sam Parent'),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpKit(
    tester,
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: ChangeNotifierProvider<SessionController>.value(
        value: session,
        child: const VerifyEmailScreen(),
      ),
    ),
    brightness: brightness,
  );

  testWidgets('it names the address the link went to', (tester) async {
    // Which is the whole point: somebody who typoed it can only tell by
    // reading it back.
    await pump(tester);
    await signIn(tester);

    expect(find.text(AppCopy.verifyEmailBlurb(email)), findsOneWidget);
  });

  testWidgets('checking again when it is still unverified says so', (
    tester,
  ) async {
    await pump(tester);
    await signIn(tester);

    await tester.tap(
      find.widgetWithText(NestButton, AppCopy.verifyEmailSubmit),
    );
    await tester.pumpAndSettle();

    expect(auth.emailVerifiedChecks, 1);
    expect(
      find.text(AppCopy.verifyEmailStillWaiting),
      findsOneWidget,
      reason: 'a button that appears to do nothing reads as a broken button',
    );
  });

  testWidgets('asking for another email says it was sent', (tester) async {
    await pump(tester);
    await signIn(tester);

    await tester.tap(
      find.widgetWithText(NestButton, AppCopy.verifyEmailResend),
    );
    await tester.pumpAndSettle();

    expect(auth.verificationEmailsSent, 1);
    expect(find.text(AppCopy.verifyEmailResent), findsOneWidget);
  });

  testWidgets('a wrong address can be escaped by signing out', (tester) async {
    // The gap this covers is named in the ADR: there is no change-address flow
    // in v1, so sign-out is the only way back and it must be on this screen.
    await pump(tester);
    await signIn(tester);

    await tester.tap(find.widgetWithText(NestButton, AppCopy.signOut));
    await tester.pumpAndSettle();

    expect(auth.signOutCount, 1);
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await signIn(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
