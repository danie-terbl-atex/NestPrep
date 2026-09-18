import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/state/household_gate_controller.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_household.dart';

/// The screen somebody sees once, on the day they join: make a household, or
/// type the code somebody sent them. Both are callables, so both need the
/// network and both can refuse — and this is the first thing a new account
/// touches, so a double tap here must not make two households.
void main() {
  late FakeHouseholdDirectory directory;
  late HouseholdGateController controller;

  setUp(() {
    directory = FakeHouseholdDirectory();
    controller = HouseholdGateController(
      householdDirectory: directory,
      suggestedName: 'Sam Parent',
      defaultTimeZone: 'Africa/Johannesburg',
    );
  });

  tearDown(() => controller.dispose());

  test('starts idle, with nothing to apologise for', () {
    expect(controller.isBusy, isFalse);
    expect(controller.failure, isNull);
  });

  test(
    'creating a household passes the name, the zone and who is asking',
    () async {
      final made = await controller.createHousehold(
        householdName: 'The Parkers',
        myName: 'Sam',
      );

      expect(made, isTrue);
      final created = directory.created.single;
      expect(created.name, 'The Parkers');
      expect(created.adminDisplayName, 'Sam');
      expect(
        created.timeZone,
        'Africa/Johannesburg',
        reason: 'the household starts in the zone the device is in',
      );
      expect(controller.isBusy, isFalse);
    },
  );

  test('a household can be started in another timezone', () async {
    await controller.createHousehold(
      householdName: 'The Parkers',
      myName: 'Sam',
      timeZone: 'Europe/London',
    );
    expect(directory.created.single.timeZone, 'Europe/London');
  });

  test('a code joins, and is passed through exactly as typed', () async {
    final joined = await controller.joinWithCode('ABCD2345');
    expect(joined, isTrue);
    expect(directory.redeemed, ['ABCD2345']);
  });

  test(
    'a code the server refuses becomes copy, and the screen stays put',
    () async {
      directory.failWith = const HouseholdFailure(
        HouseholdProblem.inviteExpired,
      );

      final joined = await controller.joinWithCode('EXPIRED1');

      expect(joined, isFalse, reason: 'the screen must not move on');
      expect(controller.failure, isA<HouseholdFailure>());
      expect(controller.isBusy, isFalse);

      controller.dismissFailure();
      expect(controller.failure, isNull);
    },
  );

  test('a double tap does not make two households', () async {
    directory.gate = Completer<void>();

    final first = controller.createHousehold(
      householdName: 'The Parkers',
      myName: 'Sam',
    );
    await pumpEventQueue();
    expect(controller.isBusy, isTrue);

    final second = await controller.createHousehold(
      householdName: 'The Parkers',
      myName: 'Sam',
    );
    expect(second, isFalse);

    directory.release();
    expect(await first, isTrue);
    expect(
      directory.created,
      hasLength(1),
      reason: 'one household, however many times the button was pressed',
    );
  });

  test('a failure from one attempt does not haunt the next', () async {
    directory.failWith = const UnavailableFailure();
    await controller.joinWithCode('ABCD2345');
    expect(controller.failure, isNotNull);

    directory.failWith = null;
    final joined = await controller.joinWithCode('ABCD2345');

    expect(joined, isTrue);
    expect(controller.failure, isNull);
  });
}
