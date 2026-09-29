import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/ui/sign_in_screen.dart';
import 'package:nestprep/features/kid_accounts/state/kid_code_controller.dart';
import 'package:nestprep/features/kid_accounts/ui/kid_code_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/kid_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_kid_sign_in.dart';
import '../../../support/pump_screen.dart';

/// The kid's way in, as a child meets it (accounts ADR-0003): six big tiles,
/// one button, and words written for them when it does not work.
void main() {
  late FakeKidSignInDirectory directory;
  late FakeAuthGateway auth;
  late KidCodeController controller;

  setUp(() {
    directory = FakeKidSignInDirectory();
    auth = FakeAuthGateway();
    controller = KidCodeController(
      kidSignInDirectory: directory,
      authGateway: auth,
    );
  });

  tearDown(() async {
    controller.dispose();
    await auth.close();
  });

  Future<void> pump(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    await pumpRouter(
      tester,
      router: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const KidCodeScreen(),
          ),
          GoRoute(
            path: SignInScreen.path,
            builder: (context, state) => const Placeholder(),
          ),
        ],
      ),
      providers: [
        ChangeNotifierProvider<KidCodeController>.value(value: controller),
      ],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pumpAndSettle();
  }

  Finder letsMeIn() => find.widgetWithText(NestButton, KidCopy.codeSubmit);

  bool isEnabled(WidgetTester tester) =>
      tester.widget<NestButton>(letsMeIn()).onPressed != null;

  testWidgets('says hello and waits for a whole code', (tester) async {
    await pump(tester);

    expect(find.text(KidCopy.codeTitle), findsOneWidget);
    expect(isEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), 'abc23');
    await tester.pump();
    expect(isEnabled(tester), isFalse);
  });

  testWidgets('each letter lands in its own tile, cleaned as it is typed', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'a0b-c 234');
    await tester.pump();

    expect(controller.code, 'ABC234');
    for (final letter in ['A', 'B', 'C', '2', '3', '4']) {
      expect(find.text(letter), findsOneWidget);
    }
    expect(isEnabled(tester), isTrue);
  });

  testWidgets('a whole code signs the device in', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'ABC234');
    await tester.pump();

    await tester.tap(letsMeIn());
    await tester.pumpAndSettle();

    expect(directory.redeemed, ['ABC234']);
    expect(auth.kidTokens, [directory.token]);
  });

  testWidgets('a code that did not work says so in a child’s words', (
    tester,
  ) async {
    directory.failWith = const KidSignInFailure(KidSignInProblem.codeNotFound);
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'ABC234');
    await tester.pump();

    await tester.tap(letsMeIn());
    await tester.pumpAndSettle();

    expect(
      find.text(KidCopy.problem(KidSignInProblem.codeNotFound)),
      findsOneWidget,
    );
    expect(auth.kidTokens, isEmpty);
  });

  testWidgets('a grown-up can go back to the grown-up way in', (tester) async {
    await pump(tester);
    await tester.tap(find.text(KidCopy.codeBackToSignIn));
    await tester.pumpAndSettle();
    expect(find.byType(Placeholder), findsOneWidget);
  });

  testWidgets('the field is labelled for a screen reader', (tester) async {
    await pump(tester);
    expect(find.bySemanticsLabel(KidCopy.codeFieldLabel), findsOneWidget);
    expect(find.bySemanticsLabel(AppCopy.back), findsOneWidget);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    directory.failWith = const KidSignInFailure(KidSignInProblem.codeExpired);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.enterText(find.byType(TextField), 'WXYZ98');
    await tester.pump();
    await tester.tap(letsMeIn(), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
