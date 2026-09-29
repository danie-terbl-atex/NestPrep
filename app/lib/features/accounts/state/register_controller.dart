import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../data/auth_gateway.dart';

/// Creating an account with an address and a password (accounts ADR-0002).
///
/// Route-scoped, like every controller that is not the session (foundation
/// ADR-0006). It keeps nothing after a success: registering signs the person
/// in, the session's auth stream fires, and the router moves them to the verify
/// screen — so there is no state here to hand over.
final class RegisterController extends ChangeNotifier {
  RegisterController({required AuthGateway authGateway}) : _auth = authGateway;

  final AuthGateway _auth;

  bool _isBusy = false;
  AppFailure? _failure;

  bool get isBusy => _isBusy;
  AppFailure? get failure => _failure;

  void dismissFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_isBusy) return false;
    _isBusy = true;
    _failure = null;
    notifyListeners();
    try {
      await _auth.registerWithEmail(
        email: email.trim(),
        password: password,
        displayName: name.trim(),
      );
      return true;
    } on AppFailure catch (failure) {
      _failure = failure;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
