import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/product_analytics/state/activity_heartbeat.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_product_analytics.dart';

/// "This household was opened today", sent at most once a day per household
/// (product-analytics ADR-0001).
void main() {
  late FakeActivityRecorder recorder;
  late DateTime now;
  late ActivityHeartbeat heartbeat;

  setUp(() {
    recorder = FakeActivityRecorder();
    now = DateTime(2026, 9, 28, 7, 30);
    heartbeat = ActivityHeartbeat(activityRecorder: recorder, now: () => now);
  });

  test('counts a household the first time it is opened in a day', () async {
    await heartbeat.beat('h1');

    expect(recorder.recorded, ['h1']);
  });

  test(
    'does not send it again the same day, however often it resumes',
    () async {
      await heartbeat.beat('h1');
      now = DateTime(2026, 9, 28, 21, 45);
      await heartbeat.beat('h1');
      await heartbeat.beat('h1');

      expect(recorder.recorded, ['h1']);
    },
  );

  test('sends it again the next day', () async {
    await heartbeat.beat('h1');
    now = DateTime(2026, 9, 29, 0, 5);
    await heartbeat.beat('h1');

    expect(recorder.recorded, ['h1', 'h1']);
  });

  test('counts each household on its own', () async {
    await heartbeat.beat('h1');
    await heartbeat.beat('h2');
    await heartbeat.beat('h1');

    expect(recorder.recorded, ['h1', 'h2']);
  });

  test(
    'sends one call for two quick resumes while the first is in flight',
    () async {
      recorder.gate = Completer<void>();
      final first = heartbeat.beat('h1');
      final second = heartbeat.beat('h1');
      recorder.gate!.complete();
      await Future.wait([first, second]);

      expect(recorder.recorded, ['h1']);
    },
  );

  test(
    'never lets a failure reach the caller — nothing on screen waits on it',
    () async {
      recorder.failWith = const UnavailableFailure();

      await expectLater(heartbeat.beat('h1'), completes);
    },
  );

  test(
    'tries again after a failure rather than counting the day as done',
    () async {
      recorder.failWith = const UnavailableFailure();
      await heartbeat.beat('h1');
      recorder.failWith = null;
      await heartbeat.beat('h1');
      await heartbeat.beat('h1');

      expect(recorder.recorded, ['h1', 'h1']);
    },
  );
}
