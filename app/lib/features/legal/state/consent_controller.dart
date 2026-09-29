import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../accounts/data/account_repository.dart';
import '../model/legal_versions.dart';

/// The consent step (accounts ADR-0005): two ticks — an adult, and agreeing
/// to both documents — and one write of the versions this build ships.
///
/// Nothing here moves the person on. The account document comes back through
/// the session's listener with the new consent, and the router lets them
/// through; this only has to make the write, once.
final class ConsentController extends ChangeNotifier {
  ConsentController({
    required AccountRepository accountRepository,
    required this.uid,
    required this.isUpdate,
  }) : _accounts = accountRepository;

  final AccountRepository _accounts;
  final String uid;

  /// This person agreed to an earlier version, so the screen says what
  /// changed rather than introducing itself.
  final bool isUpdate;

  bool _isAdult = false;
  bool _agreesToTerms = false;
  bool _isSubmitting = false;
  AppFailure? _failure;
  bool _isDisposed = false;

  bool get isAdult => _isAdult;
  bool get agreesToTerms => _agreesToTerms;
  bool get isSubmitting => _isSubmitting;
  AppFailure? get failure => _failure;
  bool get canAccept => _isAdult && _agreesToTerms && !_isSubmitting;

  void setAdult({required bool value}) {
    _isAdult = value;
    notifyListeners();
  }

  void setAgreesToTerms({required bool value}) {
    _agreesToTerms = value;
    notifyListeners();
  }

  /// Writes the acceptance. One at a time, and only with both ticks — the
  /// button is off until then, and this says so too (`FE-10`).
  Future<void> accept() async {
    if (!canAccept) return;
    _isSubmitting = true;
    _failure = null;
    notifyListeners();
    try {
      await _accounts.acceptLegal(
        uid: uid,
        termsVersion: LegalVersions.terms,
        privacyVersion: LegalVersions.privacy,
      );
    } on AppFailure catch (failure) {
      _failure = failure;
    } finally {
      _isSubmitting = false;
      // Accepting moves the router on, which can dispose this controller
      // before the write that caused it has returned.
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
