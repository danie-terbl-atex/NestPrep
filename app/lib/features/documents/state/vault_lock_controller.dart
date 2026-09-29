import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/device_lock.dart';
import '../model/vault_lock_state.dart';

/// Whether the vault is open on this phone right now (documents ADR-0003).
///
/// It lives on the Documents shell, so leaving Documents disposes it and the
/// vault is locked again. It also locks when the app goes to the background,
/// and five minutes after the last thing opened in it. This is a client
/// control: it protects a phone left unlocked on a table. What protects the
/// data is the rules.
final class VaultLockController extends ChangeNotifier
    with WidgetsBindingObserver {
  VaultLockController({
    required this._deviceLock,
    required this.reason,
    Timer Function(Duration, void Function())? startTimer,
    WidgetsBinding? binding,
  }) : _startTimer = startTimer ?? Timer.new,
       _binding = binding ?? WidgetsBinding.instance {
    _binding.addObserver(this);
  }

  /// How long the vault stays open after the last thing somebody did in it.
  static const idleLimit = Duration(minutes: 5);

  final DeviceLock _deviceLock;
  final Timer Function(Duration, void Function()) _startTimer;
  final WidgetsBinding _binding;

  /// What the system prompt says the unlock is for.
  final String reason;

  VaultLockState _state = VaultLockState.locked;
  UnlockOutcome? _lastOutcome;
  Timer? _idle;

  VaultLockState get state => _state;
  bool get isUnlocked => _state == VaultLockState.unlocked;

  /// Why the last unlock did not open the vault, for the lock screen. Null
  /// after a success, and after backing out, which is a choice.
  UnlockOutcome? get problem => switch (_lastOutcome) {
    UnlockOutcome.unlocked || UnlockOutcome.cancelled || null => null,
    final outcome => outcome,
  };

  Future<void> unlock() async {
    if (_state != VaultLockState.locked) return;
    _state = VaultLockState.unlocking;
    notifyListeners();
    final outcome = await _deviceLock.unlock(reason);
    _lastOutcome = outcome;
    _state = outcome == UnlockOutcome.unlocked
        ? VaultLockState.unlocked
        : VaultLockState.locked;
    if (isUnlocked) _restartIdle();
    notifyListeners();
  }

  /// Something happened in the vault; the five minutes start again.
  void touch() {
    if (isUnlocked) _restartIdle();
  }

  void lock() {
    _idle?.cancel();
    _idle = null;
    if (_state == VaultLockState.locked) return;
    // A prompt that is up stays up; it resolves itself, and locking under it
    // would leave the screen saying "locked" while the phone asks for a PIN.
    if (_state == VaultLockState.unlocking) return;
    _state = VaultLockState.locked;
    _lastOutcome = null;
    notifyListeners();
  }

  void _restartIdle() {
    _idle?.cancel();
    _idle = _startTimer(idleLimit, lock);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` is what the biometric prompt itself causes on iOS, so only a
    // real trip to the background locks.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      lock();
    }
  }

  @override
  void dispose() {
    _idle?.cancel();
    _binding.removeObserver(this);
    super.dispose();
  }
}
