import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../data/auth_gateway.dart';

/// Asking for a password reset link (accounts ADR-0002).
///
/// [wasSent] is true once the request went through, and it says nothing about
/// whether the address had an account: the screen shows one sentence either way,
/// because confirming which addresses are registered is the thing Firebase's
/// enumeration protection exists to prevent.
final class PasswordResetController extends ChangeNotifier {
  PasswordResetController({required AuthGateway authGateway})
    : _auth = authGateway;

  final AuthGateway _auth;

  bool _isBusy = false;
  bool _wasSent = false;
  AppFailure? _failure;

  bool get isBusy => _isBusy;
  bool get wasSent => _wasSent;
  AppFailure? get failure => _failure;

  Future<void> send(String email) async {
    if (_isBusy) return;
    _isBusy = true;
    _failure = null;
    notifyListeners();
    try {
      await _auth.sendPasswordReset(email);
      _wasSent = true;
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
