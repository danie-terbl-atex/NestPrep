import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_link_status.dart';
import 'package:nestprep/features/add_to_checkers/state/checkers_link_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_checkers.dart';

void main() {
  late FakeCheckersDirectory directory;
  late CheckersLinkController controller;
  final now = DateTime.utc(2026, 9, 30, 12);

  CheckersLinkController build() =>
      CheckersLinkController(directory: directory, now: () => now);

  setUp(() => directory = FakeCheckersDirectory());
  tearDown(() => controller.dispose());

  test('opening asks for the status and never sends a code', () async {
    controller = build();
    await pumpEventQueue();
    expect(controller.status, isA<AsyncData<CheckersLinkStatus>>());
    expect(controller.step, CheckersLinkStep.mobile);
    expect(directory.otpRequests, isEmpty);
  });

  test('a number, then the code, and it is linked', () async {
    controller = build();
    await pumpEventQueue();
    await controller.requestOtp(' 082 123 4567 ');
    expect(directory.otpRequests.single, '082 123 4567');
    expect(controller.step, CheckersLinkStep.code);
    expect(controller.codeSentTo, '+27 82 *** 4567');

    expect(await controller.verify('123456'), isTrue);
    expect(controller.step, CheckersLinkStep.linked);
  });

  test('a bad number and a wrong code belong to their fields', () async {
    controller = build();
    await pumpEventQueue();
    directory.requestFailure = const CheckersFailure(CheckersProblem.badMobile);
    await controller.requestOtp('123');
    expect(controller.fieldFailure, isA<CheckersFailure>());
    expect(controller.actionFailure, isNull);
    expect(controller.step, CheckersLinkStep.mobile);

    directory.requestFailure = null;
    await controller.requestOtp('0821234567');
    directory.verifyFailure = const CheckersFailure(CheckersProblem.wrongCode);
    expect(await controller.verify('000000'), isFalse);
    expect(controller.fieldFailure, isA<CheckersFailure>());
    expect(controller.step, CheckersLinkStep.code);
  });

  test('too many codes is said above the form, not under a field', () async {
    controller = build();
    await pumpEventQueue();
    directory.requestFailure = const CheckersFailure(
      CheckersProblem.otpRateLimited,
    );
    await controller.requestOtp('0821234567');
    expect(controller.fieldFailure, isNull);
    expect(controller.actionFailure, isA<CheckersFailure>());
    expect(controller.isBusy, isFalse);
  });

  test('a lapsed link is not linked, whatever the flag says', () async {
    directory.status = CheckersLinkStatus(
      isLinked: true,
      expiresAt: now.subtract(const Duration(minutes: 1)),
    );
    controller = build();
    await pumpEventQueue();
    expect(controller.step, CheckersLinkStep.mobile);
  });

  test('unlinking forgets the link', () async {
    directory.status = CheckersLinkStatus(
      isLinked: true,
      expiresAt: now.add(const Duration(minutes: 30)),
      mobileMasked: '+27 82 *** 4567',
    );
    controller = build();
    await pumpEventQueue();
    expect(controller.step, CheckersLinkStep.linked);
    await controller.unlink();
    expect(directory.unlinks, 1);
    expect(controller.step, CheckersLinkStep.mobile);
  });

  test(
    'a status that cannot be read is the screen’s error, with a retry',
    () async {
      directory.statusFailure = const UnavailableFailure();
      controller = build();
      await pumpEventQueue();
      expect(controller.status, isA<AsyncFailure<CheckersLinkStatus>>());
      directory.statusFailure = null;
      await controller.retry();
      expect(controller.status, isA<AsyncData<CheckersLinkStatus>>());
    },
  );
}
