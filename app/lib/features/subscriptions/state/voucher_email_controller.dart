import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/premium_voucher_directory.dart';
import 'premium_voucher_inbox.dart';

enum VoucherEmailStep { enterEmail, enterCode, confirmed }

final class VoucherEmailController extends ChangeNotifier {
  VoucherEmailController({
    required this._directory,
    required this._inbox,
    this.resendAfter = const Duration(seconds: 30),
  });

  static const codeLength = 6;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _codePattern = RegExp(r'^\d{6}$');

  final PremiumVoucherDirectory _directory;
  final PremiumVoucherInbox _inbox;
  final Duration resendAfter;

  VoucherEmailStep _step = VoucherEmailStep.enterEmail;
  String _email = '';
  String? _emailMasked;
  bool _isBusy = false;
  bool _isLookingForPremium = false;
  AppFailure? _failure;
  AppFailure? _lookupFailure;
  bool _emailInvalid = false;
  bool _codeIncomplete = false;
  bool _sendsUsedUp = false;
  int _resendIn = 0;
  Timer? _ticker;
  bool _isDisposed = false;

  VoucherEmailStep get step => _step;
  String? get emailMasked => _emailMasked;
  bool get isBusy => _isBusy;
  bool get isLookingForPremium => _isLookingForPremium;
  AppFailure? get failure => _failure;
  AppFailure? get lookupFailure => _lookupFailure;
  bool get emailInvalid => _emailInvalid;
  bool get codeIncomplete => _codeIncomplete;
  int get resendIn => _resendIn;
  bool get canResend => !_isBusy && !_sendsUsedUp && _resendIn == 0;

  static bool looksLikeEmail(String email) =>
      _emailPattern.hasMatch(email.trim());

  static String masked(String email) {
    final normal = email.trim().toLowerCase();
    final at = normal.lastIndexOf('@');
    return '${normal.isEmpty ? '' : normal.substring(0, 1)}***@'
        '${normal.substring(at + 1)}';
  }

  Future<void> send(String email) async {
    if (_isBusy) return;
    final trimmed = email.trim();
    _failure = null;
    _emailInvalid = !looksLikeEmail(trimmed);
    if (_emailInvalid) {
      _notify();
      return;
    }
    _email = trimmed;
    _sendsUsedUp = false;
    await _send();
  }

  Future<void> resend() async {
    if (!canResend) return;
    _failure = null;
    await _send();
  }

  Future<void> verify(String code) async {
    if (_isBusy) return;
    final digits = code.trim();
    _failure = null;
    _codeIncomplete = !_codePattern.hasMatch(digits);
    if (_codeIncomplete) {
      _notify();
      return;
    }
    _isBusy = true;
    _notify();
    try {
      _emailMasked = await _directory.verifyEmailCode(
        email: _email,
        code: digits,
      );
      _isBusy = false;
      await _confirm();
    } on AppFailure catch (failure) {
      _isBusy = false;
      _failure = failure;
      _notify();
    }
  }

  Future<void> retryLookup() async {
    if (_step != VoucherEmailStep.confirmed || _isLookingForPremium) return;
    await _lookUp();
  }

  void useAnotherEmail() {
    _ticker?.cancel();
    _resendIn = 0;
    _step = VoucherEmailStep.enterEmail;
    _failure = null;
    _codeIncomplete = false;
    _notify();
  }

  void clearFieldProblems() {
    if (!_emailInvalid && !_codeIncomplete && _failure == null) return;
    _emailInvalid = false;
    _codeIncomplete = false;
    if (_failure case PremiumVoucherFailure(
      problem: PremiumVoucherProblem.emailCodeWrong,
    )) {
      _failure = null;
    }
    _notify();
  }

  Future<void> _send() async {
    _isBusy = true;
    _notify();
    try {
      _emailMasked = await _directory.sendEmailCode(_email);
      _step = VoucherEmailStep.enterCode;
      _startCooldown();
    } on PremiumVoucherFailure catch (failure) {
      if (failure.problem == PremiumVoucherProblem.emailAlreadyVerified) {
        _isBusy = false;
        _failure = failure;
        _emailMasked = masked(_email);
        await _confirm();
        return;
      }
      if (failure.problem == PremiumVoucherProblem.tooManyCodes) {
        _sendsUsedUp = true;
      }
      _failure = failure;
    } on AppFailure catch (failure) {
      _failure = failure;
    }
    _isBusy = false;
    _notify();
  }

  Future<void> _confirm() async {
    _ticker?.cancel();
    _resendIn = 0;
    _step = VoucherEmailStep.confirmed;
    await _lookUp();
  }

  Future<void> _lookUp() async {
    _isLookingForPremium = true;
    _lookupFailure = null;
    _notify();
    await _inbox.refresh();
    if (_inbox.vouchers case AsyncFailure(:final failure)) {
      _lookupFailure = failure;
    }
    _isLookingForPremium = false;
    _notify();
  }

  void _startCooldown() {
    _ticker?.cancel();
    _resendIn = resendAfter.inSeconds;
    if (_resendIn == 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendIn = _resendIn > 0 ? _resendIn - 1 : 0;
      if (_resendIn == 0) timer.cancel();
      _notify();
    });
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
