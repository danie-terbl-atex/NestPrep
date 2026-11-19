import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/state/invite_welcome_controller.dart';
import 'package:nestprep/features/household/state/pending_invite.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_household.dart';

/// The invite's first step before an account exists (household ADR-0011).
void main() {
  late FakeHouseholdDirectory directory;
  late PendingInvite pending;
  late InviteWelcomeController controller;

  setUp(() {
    directory = FakeHouseholdDirectory();
    pending = PendingInvite(links: const Stream.empty())..offerCode('ABCD2345');
    controller = InviteWelcomeController(
      householdDirectory: directory,
      pendingInvite: pending,
    );
  });

  tearDown(() {
    controller.dispose();
    pending.dispose();
  });

  test('names what the held invite offers', () async {
    expect(controller.isChecking, isTrue);
    await controller.load();

    expect(directory.previewed, ['ABCD2345']);
    expect(controller.isChecking, isFalse);
    expect(controller.preview?.householdName, 'The Parkers');
    expect(controller.refusal, isNull);
  });

  for (final problem in [
    HouseholdProblem.inviteNotFound,
    HouseholdProblem.inviteExpired,
    HouseholdProblem.inviteAlreadyUsed,
    HouseholdProblem.memberAlreadyClaimed,
    HouseholdProblem.householdNotFound,
  ]) {
    test('a dead invite (${problem.name}) stops the way in', () async {
      directory.failWith = HouseholdFailure(problem);
      await controller.load();

      expect(controller.refusal, problem);
      expect(controller.preview, isNull);
    });
  }

  for (final failure in <AppFailure>[
    const UnavailableFailure(),
    const HouseholdFailure(HouseholdProblem.notSignedIn),
    const HouseholdFailure(HouseholdProblem.tooManyAttempts),
  ]) {
    test('anything else ($failure) leaves the way in open', () async {
      directory.failWith = failure;
      await controller.load();

      expect(controller.isChecking, isFalse);
      expect(controller.refusal, isNull);
      expect(controller.preview, isNull);
    });
  }

  test('not now drops the held invite', () {
    controller.notNow();
    expect(pending.code, isNull);
  });

  test('a preview that lands after the step has gone is ignored', () async {
    final leaving = InviteWelcomeController(
      householdDirectory: directory,
      pendingInvite: pending,
    );
    directory.gate = Completer<void>();
    final loading = leaving.load();
    leaving.dispose();
    directory.gate?.complete();
    await expectLater(loading, completes);
  });
}
