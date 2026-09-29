import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/model/member.dart';
import '../data/kid_device_repository.dart';
import '../data/kid_sign_in_directory.dart';
import '../model/kid_device.dart';
import '../model/kid_pairing.dart';
import '../model/kid_sign_in_entry.dart';

/// The parent's kid sign-in screen (accounts ADR-0003): which children can
/// sign in, on which devices, and the one code that may be waiting.
///
/// The code is held here and nowhere else — no client can read it back from
/// Firestore. The device list is live, which is how the screen knows the
/// moment a child's tablet has used the code: a new device appears for that
/// child, and the sheet turns into a celebration rather than a countdown.
final class KidSignInController extends ChangeNotifier
    with ActionFailureHolder {
  KidSignInController({
    required KidSignInDirectory kidSignInDirectory,
    required KidDeviceRepository kidDeviceRepository,
    required this.householdId,
    required this.members,
  }) : _directory = kidSignInDirectory,
       _repository = kidDeviceRepository {
    _subscribe();
  }

  final KidSignInDirectory _directory;
  final KidDeviceRepository _repository;
  final String householdId;

  /// The household's profiles when the screen opened, from the shell.
  final List<Member> members;

  StreamSubscription<List<KidDevice>>? _subscription;
  List<KidDevice> _devices = const [];
  AsyncState<List<KidSignInEntry>> _entries = const AsyncLoading();
  KidPairing? _pairing;
  Set<String> _devicesBeforePairing = const {};
  KidDevice? _pairedDevice;
  bool _isMakingCode = false;

  AsyncState<List<KidSignInEntry>> get entries => _entries;

  /// The code on screen, while one is.
  KidPairing? get pairing => _pairing;

  /// The device that used the code on screen, once one has.
  KidDevice? get pairedDevice => _pairedDevice;

  bool get isMakingCode => _isMakingCode;

  bool _isPairing = false;

  /// Whether the pairing sheet is open. Its refusals are shown in it, so the
  /// screen underneath does not say them a second time.
  bool get isPairing => _isPairing;

  /// The sheet opened for a fresh start: no code yet, nothing refused yet.
  void beginPairing() {
    _isPairing = true;
    _pairing = null;
    _pairedDevice = null;
    clearFailureQuietly();
    notifyListeners();
  }

  /// Makes a code for one child, retiring any they had (the server does that
  /// part). One at a time: a second tap while the first is on its way is
  /// ignored rather than making two.
  Future<void> makeCode({
    required String memberId,
    required String label,
  }) async {
    if (_isMakingCode) return;
    _isMakingCode = true;
    _pairedDevice = null;
    notifyListeners();
    await runAction(() async {
      final pairing = await _directory.createPairing(
        householdId: householdId,
        memberId: memberId,
        label: label.trim(),
      );
      _devicesBeforePairing = {for (final device in _devices) device.id};
      _pairing = pairing;
    });
    _isMakingCode = false;
    notifyListeners();
  }

  /// The sheet closed. A code nobody used is retired now rather than left to
  /// run out, so a code read aloud and then abandoned is dead at once.
  Future<void> closePairing() async {
    final pairing = _pairing;
    final wasUsed = _pairedDevice != null;
    _isPairing = false;
    _pairing = null;
    _pairedDevice = null;
    // What the sheet refused was said in the sheet; it is not the screen's.
    clearFailureQuietly();
    notifyListeners();
    if (pairing == null || wasUsed) return;
    await runAction(
      () => _directory.cancelPairing(
        householdId: householdId,
        code: pairing.code,
      ),
    );
  }

  Future<void> revoke(KidDevice device) => runAction(
    () =>
        _directory.revokeDevice(householdId: householdId, deviceUid: device.id),
  );

  Future<void> signOutEverywhere(String memberId) => runAction(
    () => _directory.resetSignIn(householdId: householdId, memberId: memberId),
  );

  Future<void> retry() async {
    await _cancel();
    _entries = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _repository
        .watchDevices(householdId)
        .listen(_onDevices, onError: _onError);
  }

  void _onDevices(List<KidDevice> devices) {
    _devices = devices;
    _entries = AsyncData(
      KidSignInEntry.from(members: members, devices: devices),
    );
    final pairing = _pairing;
    if (pairing != null && _pairedDevice == null) {
      _pairedDevice = devices
          .where(
            (device) =>
                device.memberId == pairing.memberId &&
                !_devicesBeforePairing.contains(device.id),
          )
          .firstOrNull;
    }
    notifyListeners();
  }

  void _onError(Object error) {
    _entries = AsyncFailure(
      error is AppFailure ? error : UnknownFailure(error),
    );
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
