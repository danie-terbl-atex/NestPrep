import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/app_update/data/app_restarter.dart';
import 'package:nestprep/features/app_update/data/patch_updates.dart';
import 'package:nestprep/features/app_update/ui/patch_restart_host.dart';
import 'package:nestprep/shared/copy/app_update_copy.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_app_update.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required FakePatchUpdates updates,
    FakeAppRestarter? restarter,
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) {
    final nest = brightness == Brightness.dark
        ? NestTheme.dark()
        : NestTheme.light();
    return tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PatchUpdates>.value(value: updates),
          Provider<AppRestarter>.value(value: restarter ?? FakeAppRestarter()),
        ],
        child: MaterialApp(
          theme: nestThemeData(nest),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: PatchRestartHost(child: child!),
          ),
          home: const Scaffold(
            body: Column(children: [Text('Groceries'), TextField()]),
          ),
        ),
      ),
    );
  }

  testWidgets('leaves the app alone when there is no patch', (tester) async {
    final updates = FakePatchUpdates();
    await pumpHost(tester, updates: updates);
    await tester.pump();

    expect(updates.checks, 1);
    expect(find.text(AppUpdateCopy.title), findsNothing);
    expect(find.text('Groceries').hitTestable(), findsOneWidget);
  });

  testWidgets('covers the app once the patch has downloaded', (tester) async {
    final restarter = FakeAppRestarter();
    await pumpHost(
      tester,
      updates: FakePatchUpdates([PatchReadiness.readyOnRestart]),
      restarter: restarter,
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(find.text(AppUpdateCopy.title), findsOneWidget);
    expect(find.text(AppUpdateCopy.relaunchBody), findsOneWidget);
    expect(find.text('Groceries').hitTestable(), findsNothing);
    expect(
      FocusManager.instance.primaryFocus?.context?.widget,
      isNot(isA<EditableText>()),
    );

    await tester.tap(find.text(AppUpdateCopy.relaunch));
    await tester.pump();

    expect(restarter.restarts, 1);
  });

  testWidgets('asks to close the app where it cannot reopen itself', (
    tester,
  ) async {
    await pumpHost(
      tester,
      updates: FakePatchUpdates([PatchReadiness.readyOnRestart]),
      restarter: FakeAppRestarter(relaunches: false),
    );
    await tester.pump();

    expect(find.text(AppUpdateCopy.closeBody), findsOneWidget);
    expect(find.text(AppUpdateCopy.close), findsOneWidget);
  });

  testWidgets('looks again when the app comes back from the background', (
    tester,
  ) async {
    final updates = FakePatchUpdates([
      PatchReadiness.current,
      PatchReadiness.readyOnRestart,
    ]);
    await pumpHost(tester, updates: updates);
    await tester.pump();
    await tester.pump(const Duration(minutes: 15));

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();

    expect(updates.checks, 2);
    expect(find.text(AppUpdateCopy.title), findsOneWidget);
  });

  for (final relaunches in [true, false]) {
    testWidgets('survives dark at 200% text on a 360-wide phone'
        '${relaunches ? '' : ', closing'}', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpHost(
        tester,
        updates: FakePatchUpdates([PatchReadiness.readyOnRestart]),
        restarter: FakeAppRestarter(relaunches: relaunches),
        brightness: Brightness.dark,
        textScale: 2,
      );
      await tester.pump();

      expect(find.text(AppUpdateCopy.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
