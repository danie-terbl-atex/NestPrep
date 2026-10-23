import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_pnp/model/pnp_link_status.dart';
import 'package:nestprep/features/add_to_pnp/model/pnp_sign_in_result.dart';
import 'package:nestprep/features/add_to_pnp/state/pnp_link_controller.dart';
import 'package:nestprep/features/add_to_pnp/ui/pnp_link_screen.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/copy/pnp_copy.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_pnp.dart';
import '../../../support/pump_screen.dart';

/// PnP's sign-in page in a test: two buttons standing in for a member who
/// signs in, or backs out — no web view, no network.
Widget fakeSignInPage({
  required Uri page,
  required ValueChanged<PnpSignInResult> onResult,
}) => Column(
  children: [
    Text(page.host),
    TextButton(
      onPressed: () => onResult(
        PnpSignInResult.fromRedirect(
          Uri.parse('https://www.pnp.co.za/oidc_login?code=c0de&state=s1'),
        )!,
      ),
      child: const Text('signed in'),
    ),
    TextButton(
      onPressed: () => onResult(
        PnpSignInResult.fromRedirect(
          Uri.parse('https://www.pnp.co.za/oidc_login?error=access_denied'),
        )!,
      ),
      child: const Text('backed out'),
    ),
  ],
);

Future<FakePnpDirectory> pumpLink(
  WidgetTester tester, {
  FakePnpDirectory? directory,
  Brightness brightness = Brightness.light,
  double scale = 1,
}) async {
  final fake = directory ?? FakePnpDirectory();
  await pumpScreen(
    tester,
    const PnpLinkScreen(signInPage: fakeSignInPage),
    providers: [
      ChangeNotifierProvider(create: (_) => PnpLinkController(directory: fake)),
    ],
    brightness: brightness,
    textScale: scale,
  );
  await tester.pumpAndSettle();
  return fake;
}

/// Linking a member's own Pick n Pay account on PnP's own page (add-to-pnp
/// ADR-0003): honest about who we are, the page only from a tap, only the
/// code relayed, and a way to unlink.
void main() {
  testWidgets('says NestPrep is not Pick n Pay and never sees the password', (
    tester,
  ) async {
    final directory = await pumpLink(tester);
    expect(find.text(PnpCopy.notAffiliated), findsOneWidget);
    expect(find.text(PnpCopy.passwordNote), findsOneWidget);
    expect(directory.starts, 0, reason: 'nothing opens by itself');
  });

  testWidgets('sign in on PnP’s page; only its code and state are relayed', (
    tester,
  ) async {
    final directory = await pumpLink(tester);
    await tester.tap(find.text(PnpCopy.signIn));
    await tester.pumpAndSettle();
    expect(directory.starts, 1);
    expect(find.text('login.pnp.co.za'), findsOneWidget);

    await tester.tap(find.text('signed in'));
    await tester.pumpAndSettle();
    expect(directory.completions.single, (code: 'c0de', state: 's1'));
    expect(find.text(PnpCopy.linkedTitle), findsOneWidget);
    expect(find.text(PnpCopy.unlink), findsOneWidget);
  });

  testWidgets('backing out of the page says nothing was linked', (
    tester,
  ) async {
    final directory = await pumpLink(tester);
    await tester.tap(find.text(PnpCopy.signIn));
    await tester.pumpAndSettle();
    await tester.tap(find.text('backed out'));
    await tester.pumpAndSettle();
    expect(directory.completions, isEmpty);
    expect(
      find.text(PnpCopy.problem(PnpProblem.linkCancelled)),
      findsOneWidget,
    );
    expect(find.text(PnpCopy.signIn), findsOneWidget);
  });

  testWidgets('a refused sign-in is said in words', (tester) async {
    final directory = FakePnpDirectory()
      ..completeFailure = const PnpFailure(PnpProblem.linkRefused);
    await pumpLink(tester, directory: directory);
    await tester.tap(find.text(PnpCopy.signIn));
    await tester.pumpAndSettle();
    await tester.tap(find.text('signed in'));
    await tester.pumpAndSettle();
    expect(find.text(PnpCopy.problem(PnpProblem.linkRefused)), findsOneWidget);
    expect(find.text(PnpCopy.linkedTitle), findsNothing);
  });

  testWidgets('the page can be closed without signing in', (tester) async {
    await pumpLink(tester);
    await tester.tap(find.text(PnpCopy.signIn));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(PnpCopy.closeSignIn));
    await tester.pumpAndSettle();
    expect(find.text(PnpCopy.signIn), findsOneWidget);
  });

  testWidgets('a linked account can be unlinked', (tester) async {
    final directory = FakePnpDirectory()
      ..status = PnpLinkStatus(
        isLinked: true,
        linkedAt: DateTime.utc(2026, 10, 10, 8),
      );
    await pumpLink(tester, directory: directory);
    expect(find.text(PnpCopy.linkedTitle), findsOneWidget);
    await tester.tap(find.text(PnpCopy.unlink));
    await tester.pumpAndSettle();
    expect(directory.unlinks, 1);
    expect(find.text(PnpCopy.signIn), findsOneWidget);
  });

  testWidgets('a status that cannot be read offers a retry', (tester) async {
    final directory = FakePnpDirectory()
      ..statusFailure = const UnavailableFailure();
    await pumpLink(tester, directory: directory);
    expect(
      find.text(AppCopy.failure(const UnavailableFailure())),
      findsOneWidget,
    );
    directory.statusFailure = null;
    await tester.tap(find.text(AppCopy.retry));
    await tester.pumpAndSettle();
    expect(find.text(PnpCopy.signIn), findsOneWidget);
  });

  testWidgets('survives dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpLink(tester, brightness: Brightness.dark, scale: 2);
    expect(tester.takeException(), isNull);
    final signIn = find.byKey(const ValueKey('pnp-sign-in'));
    await tester.scrollUntilVisible(signIn, 200);
    await tester.tap(signIn);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('linked, dark at 200% text on a 360-wide phone', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpLink(
      tester,
      directory: FakePnpDirectory()
        ..status = PnpLinkStatus(
          isLinked: true,
          linkedAt: DateTime.utc(2026, 10, 10, 8),
        ),
      brightness: Brightness.dark,
      scale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
