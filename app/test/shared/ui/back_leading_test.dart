import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/shared/copy/app_copy.dart';
import 'package:nestprep/shared/ui/back_leading.dart';

/// The header's back button (`FE-17`). Both throws below reached the crash
/// report from the field: a button that was still on screen when the router's
/// list of routes no longer had anything behind it.
void main() {
  Widget page(String name) => Builder(
    builder: (context) => Scaffold(
      appBar: AppBar(leading: backLeading(context), title: Text(name)),
    ),
  );

  Future<GoRouter> pump(WidgetTester tester, List<RouteBase> routes) async {
    final router = GoRouter(routes: routes);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: nestThemeData(NestTheme.light()),
      ),
    );
    return router;
  }

  testWidgets('a screen opened directly has no back button', (tester) async {
    await pump(tester, [
      GoRoute(path: '/', builder: (context, state) => page('home')),
    ]);
    expect(find.bySemanticsLabel(AppCopy.back), findsNothing);
  });

  testWidgets('a second tap while the screen is leaving does nothing', (
    tester,
  ) async {
    final router = await pump(tester, [
      GoRoute(path: '/', builder: (context, state) => page('home')),
      GoRoute(path: '/next', builder: (context, state) => page('next')),
    ]);
    unawaited(router.push('/next'));
    await tester.pumpAndSettle();

    final goBack = tester
        .widget<NestIconButton>(find.byType(NestIconButton))
        .onPressed!;
    goBack();
    await tester.pump(const Duration(milliseconds: 50));
    goBack();
    await tester.pumpAndSettle();
    goBack();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('next'), findsNothing);
  });

  testWidgets('the first screen in a shell goes back out of the shell', (
    tester,
  ) async {
    final router = await pump(tester, [
      GoRoute(path: '/', builder: (context, state) => page('home')),
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(path: '/shell', builder: (context, state) => page('inside')),
        ],
      ),
    ]);
    unawaited(router.push('/shell'));
    await tester.pumpAndSettle();
    expect(find.text('inside'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(AppCopy.back));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a screen a shell shows in place of its navigator still goes '
      'back', (tester) async {
    final router = await pump(tester, [
      GoRoute(path: '/', builder: (context, state) => page('home')),
      ShellRoute(
        builder: (context, state, child) => page('locked'),
        routes: [
          GoRoute(path: '/shell', builder: (context, state) => page('inside')),
        ],
      ),
    ]);
    unawaited(router.push('/shell'));
    await tester.pumpAndSettle();
    expect(find.text('locked'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(AppCopy.back));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('home'), findsOneWidget);
  });
}
