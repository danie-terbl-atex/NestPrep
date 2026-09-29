import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/state/password_reset_controller.dart';
import 'package:nestprep/features/accounts/ui/forgot_password_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/pump_kit.dart';

/// Asking for a link to set a new password (accounts ADR-0002).
void main() {
  late FakeAuthGateway auth;
  late PasswordResetController controller;

  setUp(() {
    auth = FakeAuthGateway();
    controller = PasswordResetController(authGateway: auth);
  });

  tearDown(() async {
    controller.dispose();
    await auth.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) => pumpKit(
    tester,
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: ChangeNotifierProvider<PasswordResetController>.value(
        value: controller,
        child: const ForgotPasswordScreen(),
      ),
    ),
    brightness: brightness,
  );

  Future<void> send(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextField).first, email);
    await tester.pump();
    await tester.tap(
      find.widgetWithText(NestButton, AppCopy.forgotPasswordSubmit),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an address is sent to the gateway once', (tester) async {
    await pump(tester);
    await send(tester, 'sam@nestprep.test');

    expect(auth.passwordResetsSentTo, ['sam@nestprep.test']);
  });

  testWidgets('the answer says nothing about whether the account exists', (
    tester,
  ) async {
    // A screen that says "no such account" is a way to find out who has one.
    // This is the test that would fail if somebody helpfully made the copy
    // more specific later.
    await pump(tester);
    await send(tester, 'nobody@nestprep.test');

    expect(find.text(AppCopy.forgotPasswordSent), findsOneWidget);
    expect(
      find.textContaining('not found', findRichText: true),
      findsNothing,
      reason: 'confirming which addresses are registered is the thing to avoid',
    );
  });

  testWidgets('the form is replaced by the confirmation, not left beside it', (
    tester,
  ) async {
    await pump(tester);
    await send(tester, 'sam@nestprep.test');

    expect(
      find.widgetWithText(NestButton, AppCopy.forgotPasswordSubmit),
      findsNothing,
      reason: 'a send button under a "sent" message invites a second send',
    );
  });

  testWidgets('a refusal is shown as words, never as an error', (tester) async {
    auth.failSendWith = const SignInFailure(SignInProblem.tooManyAttempts);
    await pump(tester);
    await send(tester, 'sam@nestprep.test');

    expect(find.byType(NestBanner), findsOneWidget);
    expect(
      find.text(AppCopy.signInProblem(SignInProblem.tooManyAttempts)),
      findsOneWidget,
    );
    expect(
      find.text(AppCopy.forgotPasswordSent),
      findsNothing,
      reason: 'a failed send must not also claim to have sent something',
    );
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1200 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
