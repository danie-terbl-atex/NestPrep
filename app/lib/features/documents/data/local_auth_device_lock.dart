import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../shared/log/app_log.dart';
import '../model/vault_lock_state.dart';
import 'device_lock.dart';

/// `local_auth`: biometrics with the device credential as the fallback, never
/// biometrics alone — the PIN is the lock, a fingerprint is a shortcut to it
/// (documents ADR-0003).
final class LocalAuthDeviceLock implements DeviceLock {
  LocalAuthDeviceLock([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<UnlockOutcome> unlock(String reason) async {
    try {
      // A phone with no screen lock has nothing to ask for; the vault does
      // not open on it rather than opening unguarded.
      if (!await _auth.isDeviceSupported()) return UnlockOutcome.noScreenLock;
      final passed = await _auth.authenticate(localizedReason: reason);
      return passed ? UnlockOutcome.unlocked : UnlockOutcome.cancelled;
    } on LocalAuthException catch (error) {
      return _outcomeOf(error);
    } on PlatformException catch (error) {
      AppLog.failure('vault unlock', code: error.code, error: error);
      return UnlockOutcome.unavailable;
    }
  }

  UnlockOutcome _outcomeOf(LocalAuthException error) {
    switch (error.code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.authInProgress:
      case LocalAuthExceptionCode.userRequestedFallback:
        return UnlockOutcome.cancelled;
      case LocalAuthExceptionCode.noCredentialsSet:
        return UnlockOutcome.noScreenLock;
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return UnlockOutcome.lockedOut;
      default:
        // The enum grows without a breaking change, so anything new is
        // logged and said as "the phone could not ask" (`ENG-10`).
        AppLog.failure('vault unlock', code: error.code.name, error: error);
        return UnlockOutcome.unavailable;
    }
  }
}
