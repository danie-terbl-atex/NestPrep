import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/product_analytics/state/activity_heartbeat.dart';
import 'package:nestprep/features/product_analytics/ui/household_activity_scope.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_product_analytics.dart';

/// The household shell counts its household as opened when it shows and when
/// the app comes back to the front (product-analytics ADR-0001).
void main() {
  late FakeActivityRecorder recorder;
  late DateTime now;

  setUp(() {
    recorder = FakeActivityRecorder();
    now = DateTime(2026, 9, 28, 7);
  });

  Future<void> pump(WidgetTester tester, {String householdId = 'h1'}) =>
      tester.pumpWidget(
        Provider<ActivityHeartbeat>(
          create: (_) =>
              ActivityHeartbeat(activityRecorder: recorder, now: () => now),
          child: HouseholdActivityScope(
            householdId: householdId,
            child: const Text('the week', textDirection: TextDirection.ltr),
          ),
        ),
      );

  testWidgets('counts the household when it first shows', (tester) async {
    await pump(tester);
    await tester.pump();

    expect(recorder.recorded, ['h1']);
    expect(find.text('the week'), findsOneWidget);
  });

  testWidgets('counts again when the app returns the next day', (tester) async {
    await pump(tester);
    await tester.pump();

    now = DateTime(2026, 9, 29, 7);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(recorder.recorded, ['h1', 'h1']);
  });

  testWidgets('does not count going to the background as opening it', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();

    now = DateTime(2026, 9, 29, 7);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(recorder.recorded, ['h1']);
  });

  testWidgets('counts the new household when the household changes', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump();
    await pump(tester, householdId: 'h2');
    await tester.pump();

    expect(recorder.recorded, ['h1', 'h2']);
  });

  testWidgets('stops listening once it is gone', (tester) async {
    await pump(tester);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    now = DateTime(2026, 9, 29, 7);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(recorder.recorded, ['h1']);
  });
}
