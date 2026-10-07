import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/accounts/state/session_controller.dart';
import 'package:nestprep/features/accounts/ui/sign_in_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_auth.dart';
import '../../../support/pump_kit.dart';

/// The first screen anybody sees, and the only one they see if it goes wrong.
/// It was at six covered lines.
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
        child: const SignInScreen(),
      ),
    ),
    brightness: brightness,
  );

  testWidgets('says what the app is, and offers the one way in', (
    tester,
  ) async {
    await pump(tester);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is NestWordmark && widget.semanticsLabel == AppCopy.appName,
      ),
      findsOneWidget,
    );
    expect(find.text(AppCopy.signInTagline), findsOneWidget);
    expect(find.text(AppCopy.signInWithGoogle), findsOneWidget);
  });

  testWidgets('tapping Google asks the gateway exactly once', (tester) async {
    await pump(tester);

    await tester.ensureVisible(find.text(AppCopy.signInWithGoogle));

    await tester.tap(find.text(AppCopy.signInWithGoogle));
    await tester.pumpAndSettle();

    expect(auth.googleSignIns, hasLength(1));
  });

  testWidgets('a refusal is shown as words, never as an error', (tester) async {
    auth.failSignInWith = const SignInFailure(SignInProblem.notConfigured);
    await pump(tester);

    await tester.ensureVisible(find.text(AppCopy.signInWithGoogle));

    await tester.tap(find.text(AppCopy.signInWithGoogle));
    await tester.pumpAndSettle();

    expect(find.byType(NestBanner), findsOneWidget);
    expect(
      find.text(AppCopy.signInProblem(SignInProblem.notConfigured)),
      findsOneWidget,
      reason: 'the provider not being enabled is on us, and says so',
    );
  });

  testWidgets('a cancelled sign-in still leaves a way to try again', (
    tester,
  ) async {
    auth.failSignInWith = const SignInFailure(SignInProblem.cancelled);
    await pump(tester);

    await tester.ensureVisible(find.text(AppCopy.signInWithGoogle));

    await tester.tap(find.text(AppCopy.signInWithGoogle));
    await tester.pumpAndSettle();

    expect(
      find.text(AppCopy.signInWithGoogle),
      findsOneWidget,
      reason: 'closing the Google sheet must not strand anybody',
    );
  });

  testWidgets('the picture is one sentence to a screen reader', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(AppCopy.signInOrbitLabel), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the way in works before the entrance has finished', (
    tester,
  ) async {
    await pump(tester);

    // No settle: this is the first frame, with the button still faded out and
    // below where it lands. Somebody who taps the moment they see it must not
    // have that tap go nowhere (`FE-15`).
    await tester.ensureVisible(find.text(AppCopy.signInWithGoogle));
    await tester.tap(find.text(AppCopy.signInWithGoogle));
    await tester.pumpAndSettle();

    expect(auth.googleSignIns, hasLength(1));
  });

  testWidgets('the screen comes to rest', (tester) async {
    await pump(tester);

    // `pumpAndSettle` throws rather than hanging if anything here repeats
    // forever, which is the whole reason the entrance is an arrival and not a
    // carousel — every other test on this screen depends on it.
    await tester.pumpAndSettle();

    expect(find.text(AppCopy.signInTagline), findsOneWidget);
  });

  testWidgets('it holds at phone width in dark at 200% text', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pump(tester, brightness: Brightness.dark, scale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppCopy.signInWithGoogle), findsOneWidget);
  });
}
