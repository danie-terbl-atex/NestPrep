import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/state/register_controller.dart';
import 'package:nestprep/features/accounts/ui/register_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/pump_kit.dart';

/// Making an account with an address and a password (accounts ADR-0002).
void main() {
  late FakeAuthGateway auth;
  late RegisterController controller;

  setUp(() {
    auth = FakeAuthGateway();
    controller = RegisterController(authGateway: auth);
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
      child: ChangeNotifierProvider<RegisterController>.value(
        value: controller,
        child: const RegisterScreen(),
      ),
    ),
    brightness: brightness,
  );

  Future<void> fillIn(
    WidgetTester tester, {
    String name = 'Sam Parent',
    String email = 'sam@nestprep.test',
    String password = 'nestprep-8',
  }) async {
    await tester.enterText(find.byType(TextField).at(0), name);
    await tester.enterText(find.byType(TextField).at(1), email);
    await tester.enterText(find.byType(TextField).at(2), password);
    await tester.pump();
  }

  testWidgets('the button will not submit an empty form', (tester) async {
    await pump(tester);

    final button = tester.widget<NestButton>(
      find.widgetWithText(NestButton, AppCopy.registerSubmit),
    );
    expect(
      button.onPressed,
      isNull,
      reason: 'a round trip to be told to type something is one nobody needed',
    );
  });

  testWidgets('a password under eight characters cannot be submitted', (
    tester,
  ) async {
    await pump(tester);
    await fillIn(tester, password: 'short');

    final button = tester.widget<NestButton>(
      find.widgetWithText(NestButton, AppCopy.registerSubmit),
    );
    expect(
      button.onPressed,
      isNull,
      reason: 'the project policy is eight; Firebase would only say so later',
    );
  });

  testWidgets('a filled form registers the typed address once', (tester) async {
    await pump(tester);
    await fillIn(tester);

    await tester.tap(find.widgetWithText(NestButton, AppCopy.registerSubmit));
    await tester.pumpAndSettle();

    expect(auth.registrations, ['sam@nestprep.test']);
  });

  testWidgets('an address that already has an account is said in words', (
    tester,
  ) async {
    auth.failSignInWith = const SignInFailure(
      SignInProblem.emailAlreadyRegistered,
    );
    await pump(tester);
    await fillIn(tester);

    await tester.tap(find.widgetWithText(NestButton, AppCopy.registerSubmit));
    await tester.pumpAndSettle();

    expect(find.byType(NestBanner), findsOneWidget);
    expect(
      find.text(AppCopy.signInProblem(SignInProblem.emailAlreadyRegistered)),
      findsOneWidget,
      reason: 'and it points at the way out, which is signing in instead',
    );
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
