import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_pnp/ui/pnp_sign_in_frame.dart';
import 'package:nestprep/shared/copy/pnp_copy.dart';

import '../../../support/pump_screen.dart';

Future<({int retries, int dismissals})> Function() pumpFrame(
  WidgetTester tester, {
  required PnpSignInPhase phase,
  bool notice = false,
  Brightness brightness = Brightness.light,
  double scale = 1,
}) {
  var retries = 0;
  var dismissals = 0;
  return () async {
    await pumpScreen(
      tester,
      Scaffold(
        body: PnpSignInFrame(
          phase: phase,
          isRefusedNoticeShown: notice,
          onRetry: () => retries++,
          onDismissNotice: () => dismissals++,
          page: const Text('the sign-in page'),
        ),
      ),
      providers: const [],
      brightness: brightness,
      textScale: scale,
    );
    await tester.pump();
    return (retries: retries, dismissals: dismissals);
  };
}

/// The frame round Pick n Pay's sign-in page (`FE-08`, `FE-09`): it holds
/// its place while loading, says in words when the page cannot be reached
/// and offers a retry, and says where to go when a link is refused.
void main() {
  testWidgets('holds the place while the page loads', (tester) async {
    await pumpFrame(tester, phase: PnpSignInPhase.loading)();
    expect(find.byKey(const ValueKey('pnp-sign-in-loading')), findsOneWidget);
    expect(find.text(PnpCopy.signInPageFailed), findsNothing);
  });

  testWidgets('shows the page once it has loaded', (tester) async {
    await pumpFrame(tester, phase: PnpSignInPhase.ready)();
    expect(find.text('the sign-in page'), findsOneWidget);
    expect(find.byKey(const ValueKey('pnp-sign-in-loading')), findsNothing);
  });

  testWidgets('a page that cannot be reached says so and retries', (
    tester,
  ) async {
    var retries = 0;
    await pumpScreen(
      tester,
      Scaffold(
        body: PnpSignInFrame(
          phase: PnpSignInPhase.failed,
          isRefusedNoticeShown: false,
          onRetry: () => retries++,
          onDismissNotice: () {},
          page: const Text('the sign-in page'),
        ),
      ),
      providers: const [],
    );
    await tester.pump();
    expect(find.text(PnpCopy.signInPageFailed), findsOneWidget);
    expect(find.text('the sign-in page'), findsNothing);
    await tester.tap(find.text(PnpCopy.signInPageRetry));
    expect(retries, 1);
  });

  testWidgets('a refused link says where to do it instead', (tester) async {
    var dismissals = 0;
    await pumpScreen(
      tester,
      Scaffold(
        body: PnpSignInFrame(
          phase: PnpSignInPhase.ready,
          isRefusedNoticeShown: true,
          onRetry: () {},
          onDismissNotice: () => dismissals++,
          page: const Text('the sign-in page'),
        ),
      ),
      providers: const [],
    );
    await tester.pump();
    expect(find.text(PnpCopy.signInPageElsewhere), findsOneWidget);
    expect(find.text('the sign-in page'), findsOneWidget);
    await tester.tap(find.text(PnpCopy.signInPageNoticeDismiss));
    expect(dismissals, 1);
  });

  for (final phase in PnpSignInPhase.values) {
    testWidgets('${phase.name}, dark at 200% text on a 360-wide phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpFrame(
        tester,
        phase: phase,
        notice: true,
        brightness: Brightness.dark,
        scale: 2,
      )();
      expect(tester.takeException(), isNull);
    });
  }
}
