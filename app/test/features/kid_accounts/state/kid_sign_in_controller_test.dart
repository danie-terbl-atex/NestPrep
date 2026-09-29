import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/tokens/nest_member_palette.dart';
import 'package:nestprep/features/household/model/member.dart';
import 'package:nestprep/features/kid_accounts/model/kid_device.dart';
import 'package:nestprep/features/kid_accounts/model/kid_sign_in_entry.dart';
import 'package:nestprep/features/kid_accounts/state/kid_sign_in_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_kid_sign_in.dart';
import '../../../support/household_fixtures.dart';

/// The parent's side of kid sign-in (accounts ADR-0003): who can sign in, on
/// which devices, the one code that may be waiting, and the moment a device
/// uses it.
void main() {
  late FakeKidSignInDirectory directory;
  late FakeKidDeviceRepository devices;
  late KidSignInController controller;

  const teen = Member(
    id: 'm-teen',
    displayName: 'Teen',
    color: MemberColor.coral,
    roleName: 'member',
    claimedBy: 'uid-teen',
  );

  KidDevice device(String id, {String memberId = Fixtures.kidMemberId}) =>
      KidDevice(
        id: id,
        memberId: memberId,
        label: 'Tablet',
        pairedBy: Fixtures.samUid,
        pairedAt: DateTime.utc(2026, 9, 29),
      );

  setUp(() {
    directory = FakeKidSignInDirectory();
    devices = FakeKidDeviceRepository();
    controller = KidSignInController(
      kidSignInDirectory: directory,
      kidDeviceRepository: devices,
      householdId: Fixtures.householdId,
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid, teen],
    );
  });

  tearDown(() async {
    controller.dispose();
    await devices.close();
  });

  List<KidSignInEntry> entriesOf() =>
      (controller.entries as AsyncData<List<KidSignInEntry>>).value;

  test('offers only unclaimed children — not an admin, a helper or a teen '
      'who already joined', () async {
    devices.emit([device('kid_a'), device('kid_b')]);
    await pumpEventQueue();

    final entries = entriesOf();
    expect(
      [for (final entry in entries) entry.member.id],
      [Fixtures.kidMemberId],
    );
    expect(entries.single.devices, hasLength(2));
  });

  test('stops offering another device at five', () {
    final entry = KidSignInEntry(
      member: Fixtures.kid,
      devices: [for (var i = 0; i < 5; i++) device('kid_$i')],
    );
    expect(entry.canAddDevice, isFalse);
  });

  test('makes a code for one child with the name the parent gave it', () async {
    devices.emit(const []);
    await pumpEventQueue();

    await controller.makeCode(
      memberId: Fixtures.kidMemberId,
      label: '  Tablet ',
    );

    expect(directory.created.single, (
      memberId: Fixtures.kidMemberId,
      label: 'Tablet',
    ));
    expect(controller.pairing?.memberId, Fixtures.kidMemberId);
    expect(controller.isMakingCode, isFalse);
  });

  test('makes one code however many times the button is pressed', () async {
    directory.holdCalls = Completer<void>();
    final first = controller.makeCode(
      memberId: Fixtures.kidMemberId,
      label: '',
    );
    await controller.makeCode(memberId: Fixtures.kidMemberId, label: '');
    directory.holdCalls!.complete();
    await first;
    expect(directory.created, hasLength(1));
  });

  test('sees the device that used the code, and not one that was there '
      'already', () async {
    devices.emit([device('kid_old')]);
    await pumpEventQueue();
    await controller.makeCode(memberId: Fixtures.kidMemberId, label: '');
    expect(controller.pairedDevice, isNull);

    devices.emit([device('kid_old'), device('kid_new')]);
    await pumpEventQueue();

    expect(controller.pairedDevice?.id, 'kid_new');
  });

  test('retires a code nobody used when the sheet closes', () async {
    await controller.makeCode(memberId: Fixtures.kidMemberId, label: '');
    final code = controller.pairing!.code;

    await controller.closePairing();

    expect(directory.cancelled, [code]);
    expect(controller.pairing, isNull);
  });

  test('but not one a device has just used', () async {
    devices.emit(const []);
    await pumpEventQueue();
    await controller.makeCode(memberId: Fixtures.kidMemberId, label: '');
    devices.emit([device('kid_new')]);
    await pumpEventQueue();

    await controller.closePairing();

    expect(directory.cancelled, isEmpty);
    expect(controller.pairedDevice, isNull);
  });

  test('signs one device out, or all of a child’s', () async {
    await controller.revoke(device('kid_a'));
    await controller.signOutEverywhere(Fixtures.kidMemberId);
    expect(directory.revoked, ['kid_a']);
    expect(directory.reset, [Fixtures.kidMemberId]);
  });

  test('keeps a refusal for the banner', () async {
    directory.failWith = const KidSignInFailure(
      KidSignInProblem.tooManyDevices,
    );
    await controller.makeCode(memberId: Fixtures.kidMemberId, label: '');
    expect(controller.actionFailure, isA<KidSignInFailure>());
    expect(controller.pairing, isNull);
  });

  test('a list it could not read is an error that can be retried', () async {
    devices.failWith(const PermissionDeniedFailure());
    await pumpEventQueue();
    expect(controller.entries, isA<AsyncFailure<List<KidSignInEntry>>>());

    await controller.retry();
    devices.emit(const []);
    await pumpEventQueue();
    expect(controller.entries, isA<AsyncData<List<KidSignInEntry>>>());
  });
}
