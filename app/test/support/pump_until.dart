import 'package:flutter_test/flutter_test.dart';

/// Lets real time pass, and pumps, until [done] — for work a widget test's
/// fake clock cannot move: a background isolate, a platform future.
///
/// A fixed real-time delay is a guess about how busy the machine is, and a
/// guess that is right on a quiet laptop fails when the machine is loaded.
/// This waits exactly as long as the work takes, up to [timeout], and fails
/// with [reason] when it never finishes rather than asserting on half a result.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  required String reason,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('gave up after ${timeout.inSeconds} s: $reason');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
