import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/woolworths_account_sign_in.dart';
import '../data/woolworths_directory.dart';
import '../model/woolworths_link_status.dart';
import '../model/woolworths_sign_in.dart';

enum WoolworthsLinkStep { account, code, linked }

/// Linking the signed-in member's own Woolworths account
/// (add-to-woolworths ADR-0001): the phone signs in to Woolworths with the
/// email and password — and a code, when Woolworths sends one — and hands
/// only the refresh token to the server. Neither the password nor the token
/// is kept here. Also where it is unlinked.
///
/// One request at a time (`FE-10`); a refusal that belongs to a field is
/// held as [fieldFailure], anything else as the action failure.
final class WoolworthsLinkController extends ChangeNotifier
    with ActionFailureHolder {
  WoolworthsLinkController({
    required WoolworthsDirectory directory,
    required this._signIn,
  }) : _woolworths = directory {
    unawaited(_load());
  }

  final WoolworthsDirectory _woolworths;
  final WoolworthsAccountSignIn _signIn;

  AsyncState<WoolworthsLinkStatus> _status = const AsyncLoading();
  WoolworthsCodeAsked? _codeAsked;
  AppFailure? _fieldFailure;
  var _isBusy = false;
  var _isDisposed = false;

  AsyncState<WoolworthsLinkStatus> get status => _status;

  /// Where Woolworths sent the code it is waiting for, when it said.
  String? get codeSentTo => _codeAsked?.sentTo;

  AppFailure? get fieldFailure => _fieldFailure;

  bool get isBusy => _isBusy;

  WoolworthsLinkStep get step {
    if (_status case AsyncData(:final value) when value.isLinked) {
      return WoolworthsLinkStep.linked;
    }
    return _codeAsked == null
        ? WoolworthsLinkStep.account
        : WoolworthsLinkStep.code;
  }

  bool get isLinked => step == WoolworthsLinkStep.linked;

  Future<void> retry() => _load();

  /// Answers whether the account is now linked.
  Future<bool> signIn({required String email, required String password}) async {
    await _run(() async {
      final cognito = await _woolworths.startLink();
      await _carryOn(
        await _signIn.signIn(
          cognito: cognito,
          email: email.trim(),
          password: password,
        ),
      );
    });
    return isLinked;
  }

  /// Answers whether the account is now linked.
  Future<bool> verify(String code) async {
    final asked = _codeAsked;
    if (asked == null) return false;
    await _run(() async => _carryOn(await _signIn.answer(asked, code.trim())));
    return isLinked;
  }

  /// Back to the email and password.
  void startOver() {
    _codeAsked = null;
    _fieldFailure = null;
    notifyListeners();
  }

  void clearFieldFailure() {
    if (_fieldFailure == null) return;
    _fieldFailure = null;
    notifyListeners();
  }

  Future<void> unlink() => _run(() async {
    await _woolworths.unlink();
    _codeAsked = null;
    _status = const AsyncData(WoolworthsLinkStatus.unlinked());
  });

  Future<void> _carryOn(WoolworthsSignInStep step) async {
    switch (step) {
      case WoolworthsCodeAsked():
        _codeAsked = step;
      case WoolworthsSignedIn(:final refreshToken):
        _codeAsked = null;
        _status = AsyncData(
          await _woolworths.completeLink(refreshToken: refreshToken),
        );
    }
  }

  Future<void> _load() async {
    _status = const AsyncLoading();
    notifyListeners();
    AsyncState<WoolworthsLinkStatus> loaded;
    try {
      loaded = AsyncData(await _woolworths.linkStatus());
    } on AppFailure catch (failure) {
      loaded = AsyncFailure(failure);
    }
    if (_isDisposed) return;
    _status = loaded;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_isBusy) return;
    _isBusy = true;
    _fieldFailure = null;
    clearFailureQuietly();
    notifyListeners();
    AppFailure? refusal;
    try {
      await action();
    } on AppFailure catch (failure) {
      if (_belongsToField(failure)) {
        _fieldFailure = failure;
      } else {
        refusal = failure;
      }
      if (_endsSignIn(failure)) _codeAsked = null;
    }
    _isBusy = false;
    if (_isDisposed) return;
    refusal == null ? notifyListeners() : recordFailure(refusal);
  }

  static bool _belongsToField(AppFailure failure) => switch (failure) {
    WoolworthsFailure(
      problem: WoolworthsProblem.wrongSignIn || WoolworthsProblem.wrongCode,
    ) =>
      true,
    _ => false,
  };

  static bool _endsSignIn(AppFailure failure) => switch (failure) {
    WoolworthsFailure(
      problem: WoolworthsProblem.signInExpired ||
          WoolworthsProblem.linkRejected ||
          WoolworthsProblem.cannotLinkHere,
    ) =>
      true,
    _ => false,
  };

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
