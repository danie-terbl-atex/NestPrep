import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/assistants/state/connected_assistants_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/household_clock.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../../../support/fake_assistants.dart';
import '../../../support/household_fixtures.dart';

/// What *Connected assistants* reads for whom, and what its two actions do
/// when they are refused (assistants ADR-0003, ADR-0005).
void main() {
  late FakeAssistantRepository repository;

  setUpAll(tz_data.initializeTimeZones);
  setUp(() => repository = FakeAssistantRepository());
  tearDown(() => repository.close());

  ConnectedAssistantsController controllerFor({
    String viewerUid = Fixtures.samUid,
    String viewerMemberId = Fixtures.samMemberId,
    bool isFamily = true,
  }) {
    final controller = ConnectedAssistantsController(
      assistantRepository: repository,
      householdClock: HouseholdClock(
        'Africa/Johannesburg',
        now: () => assistantsNow,
      ),
      householdId: Fixtures.householdId,
      viewerUid: viewerUid,
      viewerMemberId: viewerMemberId,
      isFamily: isFamily,
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('family read every connection and all the activity', () {
    controllerFor();
    expect(repository.connectionOwners, [null]);
    expect(repository.activityMembers, [null]);
  });

  test('anybody else reads only their own, which is all the rules let '
      'them list', () {
    controllerFor(
      viewerUid: Fixtures.thandiUid,
      viewerMemberId: Fixtures.thandiMemberId,
      isFamily: false,
    );
    expect(repository.connectionOwners, [Fixtures.thandiUid]);
    expect(repository.activityMembers, [Fixtures.thandiMemberId]);
  });

  test('lists the viewer’s own first, then the newest', () async {
    final controller = controllerFor();
    repository.emitConnections([
      claudeConnection(id: 'g-lee', uid: 'uid-lee', memberId: 'm-lee'),
      claudeConnection(),
    ]);
    await pumpEventQueue();
    final ids = switch (controller.connections) {
      AsyncData(:final value) => [for (final c in value) c.id],
      _ => <String>[],
    };
    expect(ids, ['g-sam', 'g-lee']);
  });

  test('keeps each connection’s three latest changes, newest first', () async {
    final controller = controllerFor();
    repository
      ..emitConnections([claudeConnection()])
      ..emitActivity([
        for (var minutes = 1; minutes <= 5; minutes++)
          assistantActivity('a$minutes', ago: Duration(minutes: minutes)),
        assistantActivity('other', grantId: 'g-lee'),
      ]);
    await pumpEventQueue();
    expect(
      [for (final a in controller.recentActivityOf(claudeConnection())) a.id],
      ['a1', 'a2', 'a3'],
    );
  });

  test('a disconnect the server refuses is held for the screen, and the '
      'connection stays', () async {
    final controller = controllerFor();
    repository
      ..emitConnections([claudeConnection()])
      ..failWritesWith = const PermissionDeniedFailure();
    await pumpEventQueue();
    await controller.disconnect(claudeConnection());
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
    expect(controller.isBusy(claudeConnection()), isFalse);
    expect(repository.disconnected, isEmpty);
  });

  test('a switch flipped with no signal is held for the screen', () async {
    final controller = controllerFor();
    repository
      ..emitAllowed(true)
      ..failWritesWith = const UnavailableFailure();
    await pumpEventQueue();
    await controller.setAllowed(false);
    expect(controller.actionFailure, isA<UnavailableFailure>());
    expect(controller.allowed, isTrue);
    expect(controller.isSwitching, isFalse);
  });

  test('the switch is signed by the family member who flips it', () async {
    final controller = controllerFor();
    await controller.setAllowed(false);
    expect(repository.allowedWrites.single, (
      allowed: false,
      memberId: Fixtures.samMemberId,
    ));
  });

  test('somebody who is not family cannot flip it', () async {
    final controller = controllerFor(
      viewerUid: Fixtures.thandiUid,
      viewerMemberId: Fixtures.thandiMemberId,
      isFamily: false,
    );
    await controller.setAllowed(false);
    expect(repository.allowedWrites, isEmpty);
  });

  test('a failed activity read is a banner, not the list’s failure', () async {
    final controller = controllerFor();
    repository
      ..emitConnections([claudeConnection()])
      ..failActivityWith(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(controller.connections, isA<AsyncData<Object?>>());
    expect(controller.actionFailure, isA<PermissionDeniedFailure>());
  });

  test('a failed list read can be tried again', () async {
    final controller = controllerFor();
    repository.failConnectionsWith(const UnavailableFailure());
    await pumpEventQueue();
    expect(controller.connections, isA<AsyncFailure<Object?>>());
    await controller.retry();
    repository.emitConnections([]);
    await pumpEventQueue();
    expect(controller.connections, isA<AsyncData<Object?>>());
  });
}
