import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scrolls [finder] to the middle of its list. `tester.ensureVisible` stops
/// as soon as it is inside the viewport, which on a tab screen can still be
/// under the bottom bar the list scrolls beneath — and a tap there lands on
/// the bar.
Future<void> bringIntoView(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
}
