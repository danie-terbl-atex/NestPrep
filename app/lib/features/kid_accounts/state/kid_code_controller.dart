import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../accounts/data/auth_gateway.dart';
import '../data/kid_sign_in_directory.dart';

/// The kid's way in (accounts ADR-0003): six letters typed, traded for a token,
/// signed in with. The router takes it from there — the session becomes a
/// kid's, and the kid's home is the only place it may be.
final class KidCodeController extends ChangeNotifier {
  KidCodeController({
    required KidSignInDirectory kidSignInDirectory,
    required AuthGateway authGateway,
  }) : _directory = kidSignInDirectory,
       _auth = authGateway;

  /// Mirrors the Functions' `KID_CODE_LENGTH`.
  static const codeLength = 6;

  /// The letters a code is made of — the invite alphabet, with no 0/O and no
  /// 1/I/L. Anything else typed is dropped as it is typed, so a child never
  /// gets as far as being told a letter was wrong (`FE-10`).
  static const alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

  final KidSignInDirectory _directory;
  final AuthGateway _auth;

  String _code = '';
  bool _isSubmitting = false;
  AppFailure? _failure;

  String get code => _code;
  bool get isSubmitting => _isSubmitting;
  AppFailure? get failure => _failure;
  bool get isComplete => _code.length == codeLength;

  /// What a typed string becomes as a code: upper case, only our letters, and
  /// no longer than a code is.
  static String normalise(String typed) {
    final kept = typed.toUpperCase().split('').where(alphabet.contains).join();
    return kept.length > codeLength ? kept.substring(0, codeLength) : kept;
  }

  void setCode(String typed) {
    final next = normalise(typed);
    if (next == _code && _failure == null) return;
    _code = next;
    _failure = null;
    notifyListeners();
  }

  /// Redeems the code and signs in. One attempt at a time, and only a whole
  /// code — the button is off until then, and this says so too.
  Future<void> submit() async {
    if (_isSubmitting || !isComplete) return;
    _isSubmitting = true;
    _failure = null;
    notifyListeners();
    try {
      final token = await _directory.redeem(_code);
      await _auth.signInWithKidToken(token);
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _isSubmitting = false;
      // Signing in moves the router to the kid's home, which can dispose this
      // screen's controller before the call that caused it has returned.
      if (!_isDisposed) notifyListeners();
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
