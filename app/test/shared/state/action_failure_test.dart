import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/state/action_failure.dart';

/// The one place a refused action is held, and the check that it stays one.
///
/// Five controllers carried a byte-identical `dismissActionFailure` and four a
/// byte-identical `_run` — `ENG-01`'s "two of anything is a bug waiting for one
/// of them to be fixed", five times over.
final class _Controller extends ChangeNotifier with ActionFailureHolder {
  int notifications = 0;

  @override
  void notifyListeners() {
    notifications++;
    super.notifyListeners();
  }

  Future<void> run(Future<void> Function() action) => runAction(action);
}

void main() {
  late _Controller controller;

  setUp(() => controller = _Controller());
  tearDown(() => controller.dispose());

  test('an action that works leaves nothing to apologise for', () async {
    await controller.run(() async {});
    expect(controller.actionFailure, isNull);
  });

  test('a refusal is held and told, not thrown at the screen', () async {
    await controller.run(() async => throw const PermissionDeniedFailure());

    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    expect(controller.notifications, 1, reason: 'the screen is told once');
  });

  test('and dismissing it tells the screen exactly once', () {
    controller
      ..recordFailure(const UnavailableFailure())
      ..dismissActionFailure()
      ..dismissActionFailure();

    expect(controller.actionFailure, isNull);
    expect(
      controller.notifications,
      2,
      reason: 'dismissing nothing must not rebuild the screen',
    );
  });

  test('the next action clears the last one', () async {
    controller.recordFailure(const UnavailableFailure());
    await controller.run(() async {});
    expect(controller.actionFailure, isNull);
  });

  test('anything that is not a refusal is a bug and is left alone', () async {
    // An AppFailure is something the person can be told about. A StateError is
    // ours, and must reach the zone and the crash report rather than becoming
    // a banner that blames them.
    await expectLater(
      controller.run(() async => throw StateError('ours')),
      throwsStateError,
    );
    expect(controller.actionFailure, isNull);
  });

  test('every controller uses it rather than writing it again', () {
    final controllers = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_controller.dart'))
        .toList();

    final offences = [
      for (final file in controllers)
        if (file.readAsStringSync().contains('AppFailure? _actionFailure;'))
          file.path,
    ];

    expect(
      offences,
      isEmpty,
      reason:
          'a controller holding its own copy is the fifth copy coming '
          'back — use ActionFailureHolder (`ENG-01`)',
    );
  });
}
