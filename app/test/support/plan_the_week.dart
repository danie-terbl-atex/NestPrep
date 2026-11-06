import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bring_into_view.dart';

final Finder planTheWeekButton = find.byKey(const ValueKey('plan-week-choose'));

Future<void> tapPlanTheWeek(WidgetTester tester) async {
  await bringIntoView(tester, planTheWeekButton);
  await tester.tap(planTheWeekButton);
  await tester.pumpAndSettle();
}

Future<void> planTheWeekWith(WidgetTester tester, Finder way) async {
  await tapPlanTheWeek(tester);
  await tester.tap(way);
  await tester.pumpAndSettle();
}
