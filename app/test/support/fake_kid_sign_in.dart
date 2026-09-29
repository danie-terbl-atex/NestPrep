import 'dart:async';

import 'package:nestprep/features/kid_accounts/data/kid_device_repository.dart';
import 'package:nestprep/features/kid_accounts/data/kid_sign_in_directory.dart';
import 'package:nestprep/features/kid_accounts/model/kid_device.dart';
import 'package:nestprep/features/kid_accounts/model/kid_pairing.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// The five kid sign-in callables, without a network (accounts ADR-0003). A
/// test sees which call a screen made and plays out what the server says.
final class FakeKidSignInDirectory implements KidSignInDirectory {
  /// Set to make the next call refuse the way the Function would.
  AppFailure? failWith;

  /// What `redeem` hands back as the device's custom token.
  String token = 'custom-token';

  /// When the next code runs out; ten minutes from the real clock by default.
  DateTime? expiresAt;

  /// Held open by a test that wants to see the screen while a call is in
  /// flight.
  Completer<void>? holdCalls;

  final created = <({String memberId, String label})>[];
  final cancelled = <String>[];
  final redeemed = <String>[];
  final revoked = <String>[];
  final reset = <String>[];
  var _codes = 0;

  @override
  Future<KidPairing> createPairing({
    required String householdId,
    required String memberId,
    required String label,
  }) async {
    await _answer();
    created.add((memberId: memberId, label: label));
    _codes += 1;
    return KidPairing(
      code: 'ABC23$_codes',
      memberId: memberId,
      expiresAt:
          expiresAt ?? DateTime.now().toUtc().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<void> cancelPairing({
    required String householdId,
    required String code,
  }) async {
    await _answer();
    cancelled.add(code);
  }

  @override
  Future<String> redeem(String code) async {
    await _answer();
    redeemed.add(code);
    return token;
  }

  @override
  Future<void> revokeDevice({
    required String householdId,
    required String deviceUid,
  }) async {
    await _answer();
    revoked.add(deviceUid);
  }

  @override
  Future<void> resetSignIn({
    required String householdId,
    required String memberId,
  }) async {
    await _answer();
    reset.add(memberId);
  }

  Future<void> _answer() async {
    await holdCalls?.future;
    final failure = failWith;
    if (failure != null) throw failure;
  }
}

/// The household's kid devices, driven by hand.
final class FakeKidDeviceRepository implements KidDeviceRepository {
  final _devices = StreamController<List<KidDevice>>.broadcast();

  void emit(List<KidDevice> devices) => _devices.add(devices);
  void failWith(Object error) => _devices.addError(error);
  Future<void> close() => _devices.close();

  @override
  Stream<List<KidDevice>> watchDevices(String householdId) => _devices.stream;
}
