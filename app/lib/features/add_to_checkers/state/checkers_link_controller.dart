import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/checkers_directory.dart';
import '../model/checkers_link_status.dart';

/// The three steps of linking a Checkers account.
enum CheckersLinkStep { mobile, code, linked }

/// Linking the signed-in member's own Checkers Sixty60 account (the Checkers
/// build contract): a mobile number, the code Checkers texts to it, and then
/// an hour-long link the server keeps. Also where it is unlinked.
///
/// A code is only ever asked for by a tap on *Send code* — never on opening
/// the screen. One request at a time (`FE-10`); a refusal that belongs to a
/// field is held as [fieldFailure] for the screen to put under it, anything
/// else as the action failure.
final class CheckersLinkController extends ChangeNotifier
    with ActionFailureHolder {
  CheckersLinkController({
    required CheckersDirectory directory,
    DateTime Function()? now,
  }) : _checkers = directory,
       _now = now ?? DateTime.now {
    unawaited(_load());
  }

  final CheckersDirectory _checkers;
  final DateTime Function() _now;

  AsyncState<CheckersLinkStatus> _status = const AsyncLoading();
  String? _codeSentTo;
  AppFailure? _fieldFailure;
  var _isBusy = false;
  var _isDisposed = false;

  AsyncState<CheckersLinkStatus> get status => _status;

  /// The masked number a code was just texted to.
  String? get codeSentTo => _codeSentTo;

  /// Why what is in the field was refused — a bad number or a wrong code.
  AppFailure? get fieldFailure => _fieldFailure;

  bool get isBusy => _isBusy;

  CheckersLinkStep get step {
    if (_status case AsyncData(:final value) when value.isLiveAt(_now())) {
      return CheckersLinkStep.linked;
    }
    return _codeSentTo == null
        ? CheckersLinkStep.mobile
        : CheckersLinkStep.code;
  }

  bool get isLinked => step == CheckersLinkStep.linked;

  Future<void> retry() => _load();

  Future<void> requestOtp(String mobile) => _run(() async {
    _codeSentTo = await _checkers.requestOtp(mobile.trim());
  });

  /// Answers whether the account is now linked.
  Future<bool> verify(String code) async {
    await _run(() async {
      _status = AsyncData(await _checkers.verifyOtp(code.trim()));
    });
    return isLinked;
  }

  /// Back to the number, to text a code somewhere else.
  void changeNumber() {
    _codeSentTo = null;
    _fieldFailure = null;
    notifyListeners();
  }

  void clearFieldFailure() {
    if (_fieldFailure == null) return;
    _fieldFailure = null;
    notifyListeners();
  }

  Future<void> unlink() => _run(() async {
    await _checkers.unlink();
    _codeSentTo = null;
    _status = const AsyncData(CheckersLinkStatus.unlinked());
  });

  Future<void> _load() async {
    _status = const AsyncLoading();
    notifyListeners();
    AsyncState<CheckersLinkStatus> loaded;
    try {
      loaded = AsyncData(await _checkers.linkStatus());
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
    }
    _isBusy = false;
    if (_isDisposed) return;
    refusal == null ? notifyListeners() : recordFailure(refusal);
  }

  static bool _belongsToField(AppFailure failure) => switch (failure) {
    CheckersFailure(
      problem: CheckersProblem.badMobile ||
          CheckersProblem.wrongCode ||
          CheckersProblem.noPendingOtp,
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
