import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/home_care_access.dart';
import 'package:nestprep/features/home_care/model/shift/helper_shift.dart';
import 'package:nestprep/features/home_care/state/helper_shifts_controller.dart';
import 'package:nestprep/features/household/model/access_level.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_home_care_v2.dart';
import '../../../support/household_fixtures.dart';

/// A helper's clock (home-care ADR-0007): she asks for exactly her shifts,
/// starts one only while none is open, and ends her own; family reads
/// everybody's and ends anybody's.
void main() {
  late FakeHelperShiftRepository shifts;

  const family = HomeCareAccess(
    level: AccessLevel.edit,
    viewerMemberId: Fixtures.samMemberId,
  );
  const cleaner = HomeCareAccess(
    level: AccessLevel.own,
    viewerMemberId: Fixtures.thandiMemberId,
    isWorker: true,
  );

  HelperShift shift({
    String id = 'shift-1',
    String helperId = Fixtures.thandiMemberId,
    bool isOpen = true,
  }) => HelperShift(
    id: id,
    helperId: helperId,
    startedBy: helperId,
    startedAt: DateTime.utc(2026, 11, 13, 5, 30),
    endedAt: isOpen ? null : DateTime.utc(2026, 11, 13, 14),
    status: isOpen ? HelperShift.open : HelperShift.ended,
  );

  Future<HelperShiftsController> controllerFor(
    HomeCareAccess access, {
    bool isOn = true,
    List<HelperShift>? answered = const [],
  }) async {
    final controller = HelperShiftsController(
      repository: shifts,
      householdId: Fixtures.householdId,
    )..follow(access, isOn: isOn);
    addTearDown(controller.dispose);
    await pumpEventQueue();
    if (answered != null && isOn) {
      shifts.emitShifts(answered);
      await pumpEventQueue();
    }
    return controller;
  }

  setUp(() => shifts = FakeHelperShiftRepository());
  tearDown(() => shifts.close());

  group('what is read', () {
    test('nothing while the switch is off', () async {
      final controller = await controllerFor(cleaner, isOn: false);
      expect(controller.isAvailable, isFalse);
      expect(controller.clocksIn, isFalse);
      expect(shifts.shiftsAskedFor, isEmpty);
    });

    test('a helper asks for exactly her own; family for everybody’s', () async {
      await controllerFor(cleaner);
      await controllerFor(family);
      expect(shifts.shiftsAskedFor, [Fixtures.thandiMemberId, null]);
    });

    test('only a helper or carer clocks in', () async {
      expect((await controllerFor(cleaner)).clocksIn, isTrue);
      expect((await controllerFor(family)).clocksIn, isFalse);
    });

    test('a read that fails is said, and can be tried again', () async {
      final controller = await controllerFor(cleaner, answered: null);
      shifts.failShiftsWith(const PermissionDeniedFailure());
      await pumpEventQueue();
      expect(controller.shifts, isA<AsyncFailure<List<HelperShift>>>());
      await controller.retry();
      expect(controller.shifts, isA<AsyncLoading<List<HelperShift>>>());
      expect(shifts.shiftsAskedFor, hasLength(2));
    });
  });

  group('clocking in', () {
    test('starts her own shift in her own name', () async {
      final controller = await controllerFor(cleaner);
      await controller.start();
      expect(shifts.writes.single.$1, 'startShift');
      expect(shifts.writes.single.$2, {
        'helperId': Fixtures.thandiMemberId,
        'by': Fixtures.thandiMemberId,
      });
    });

    test('does nothing while she is already on shift', () async {
      final controller = await controllerFor(cleaner, answered: [shift()]);
      expect(controller.ownOpenShift?.id, 'shift-1');
      await controller.start();
      expect(shifts.writes, isEmpty);
    });

    test('does nothing before the shifts have been read', () async {
      final controller = await controllerFor(cleaner, answered: null);
      await controller.start();
      expect(shifts.writes, isEmpty);
    });

    test('a second tap while one is on its way writes once', () async {
      final controller = await controllerFor(cleaner);
      shifts.gate = Completer<void>();
      final first = controller.start();
      final second = controller.start();
      expect(controller.isBusy, isTrue);
      shifts.gate!.complete();
      await Future.wait([first, second]);
      expect(shifts.methods, ['startShift']);
      expect(controller.isBusy, isFalse);
    });

    test('a refused start is kept for the screen, and settles', () async {
      final controller = await controllerFor(cleaner);
      shifts.failWritesWith = const PermissionDeniedFailure();
      await controller.start();
      expect(controller.actionFailure, isA<PermissionDeniedFailure>());
      expect(controller.isBusy, isFalse);
    });
  });

  group('clocking out', () {
    test('a helper ends her own', () async {
      final controller = await controllerFor(cleaner, answered: [shift()]);
      await controller.end(controller.ownOpenShift!);
      expect(shifts.writes.single.$1, 'endShift');
      expect(shifts.writes.single.$2, {
        'shiftId': 'shift-1',
        'by': Fixtures.thandiMemberId,
      });
    });

    test('family ends one somebody forgot, in their own name', () async {
      final open = shift();
      final controller = await controllerFor(family, answered: [open]);
      expect(controller.ownOpenShift, isNull);
      expect(controller.canEnd(open), isTrue);
      await controller.end(open);
      expect(shifts.writes.single.$2['by'], Fixtures.samMemberId);
    });

    test('nobody ends somebody else’s, or one that has ended', () async {
      final others = shift(helperId: 'm-other');
      final done = shift(id: 'shift-0', isOpen: false);
      final controller = await controllerFor(cleaner, answered: [others, done]);
      await controller.end(others);
      await controller.end(done);
      expect(shifts.writes, isEmpty);
    });
  });
}
