import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_woolworths/model/woolworths_link_status.dart';
import 'package:nestprep/features/add_to_woolworths/state/woolworths_link_controller.dart';
import 'package:nestprep/features/add_to_woolworths/ui/woolworths_link_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/woolworths_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_woolworths.dart';
import '../../../support/pump_screen.dart';

typedef Fakes = ({
  FakeWoolworthsDirectory directory,
  FakeWoolworthsSignIn signIn,
});

Future<Fakes> pumpLink(
  WidgetTester tester, {
  FakeWoolworthsDirectory? directory,
  FakeWoolworthsSignIn? signIn,
  Brightness brightness = Brightness.light,
  double scale = 1,
}) async {
  final fakes = (
    directory: directory ?? FakeWoolworthsDirectory(),
    signIn: signIn ?? FakeWoolworthsSignIn(),
  );
  await pumpScreen(
    tester,
    const WoolworthsLinkScreen(),
    providers: [
      ChangeNotifierProvider(
        create: (_) => WoolworthsLinkController(
          directory: fakes.directory,
          signIn: fakes.signIn,
        ),
      ),
    ],
    brightness: brightness,
    textScale: scale,
  );
  await tester.pumpAndSettle();
  return fakes;
}

Future<void> signIn(WidgetTester tester) async {
  Future<Finder> shown(String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    return finder;
  }

  await tester.enterText(await shown('woolworths-email'), 'sam@example.com');
  await tester.enterText(await shown('woolworths-password'), 'secret');
  await tester.pump();
  await tester.tap(await shown('woolworths-sign-in'));
  await tester.pumpAndSettle();
}

/// Linking a member's own Woolworths account: honest about who we are and
/// where the password goes, a code when Woolworths sends one, and a way to
/// unlink.
void main() {
  testWidgets('says NestPrep is not Woolworths and never sees the password', (
    tester,
  ) async {
    final fakes = await pumpLink(tester);
    expect(find.text(WoolworthsCopy.notAffiliated), findsOneWidget);
    expect(find.text(WoolworthsCopy.passwordNote), findsOneWidget);
    expect(fakes.signIn.signIns, isEmpty);
  });

  testWidgets('sign in is off until there is an email and a password', (
    tester,
  ) async {
    final fakes = await pumpLink(tester);
    await tester.enterText(
      find.byKey(const ValueKey('woolworths-email')),
      'sam',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('woolworths-sign-in')));
    await tester.pump();
    expect(fakes.signIn.signIns, isEmpty);
  });

  testWidgets('email and password, linked', (tester) async {
    final fakes = await pumpLink(tester);
    await signIn(tester);
    expect(fakes.signIn.signIns.single.email, 'sam@example.com');
    expect(find.text(WoolworthsCopy.linkedTitle), findsOneWidget);
    expect(
      find.text(WoolworthsCopy.linkedAs('p***@o***.nest')),
      findsOneWidget,
    );
  });

  testWidgets('a code, when Woolworths sends one', (tester) async {
    final fakes = await pumpLink(
      tester,
      signIn: FakeWoolworthsSignIn()..asksForCode = true,
    );
    await signIn(tester);
    expect(
      find.text(WoolworthsCopy.codeSentTo('+27*****4567')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('woolworths-code')),
      '123456',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('woolworths-verify')));
    await tester.pumpAndSettle();
    expect(fakes.signIn.answers, ['123456']);
    expect(find.text(WoolworthsCopy.linkedTitle), findsOneWidget);
  });

  testWidgets('a wrong password is said under the field', (tester) async {
    await pumpLink(
      tester,
      signIn: FakeWoolworthsSignIn()
        ..signInFailure = const WoolworthsFailure(
          WoolworthsProblem.wrongSignIn,
        ),
    );
    await signIn(tester);
    expect(
      find.text(
        AppCopy.failure(const WoolworthsFailure(WoolworthsProblem.wrongSignIn)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a linked account can be unlinked', (tester) async {
    final directory = FakeWoolworthsDirectory()
      ..status = WoolworthsLinkStatus(
        isLinked: true,
        linkedAt: DateTime.utc(2026, 11, 1, 9),
        emailMasked: 'd***@a***.io',
      );
    await pumpLink(tester, directory: directory);
    expect(find.text(WoolworthsCopy.linkedAs('d***@a***.io')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('woolworths-unlink')));
    await tester.pumpAndSettle();
    expect(directory.unlinks, 1);
    expect(find.text(WoolworthsCopy.signIn), findsOneWidget);
  });

  testWidgets('a status that cannot be read offers a retry', (tester) async {
    final directory = FakeWoolworthsDirectory()
      ..statusFailure = const UnavailableFailure();
    await pumpLink(tester, directory: directory);
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    directory.statusFailure = null;
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text(WoolworthsCopy.signIn), findsOneWidget);
  });

  for (final asksForCode in [false, true]) {
    testWidgets('survives dark at 200% text on a 360-wide phone'
        '${asksForCode ? ', at the code' : ''}', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpLink(
        tester,
        signIn: FakeWoolworthsSignIn()..asksForCode = asksForCode,
        brightness: Brightness.dark,
        scale: 2,
      );
      if (asksForCode) await signIn(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
