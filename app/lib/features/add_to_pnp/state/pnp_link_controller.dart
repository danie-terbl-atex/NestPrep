import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/pnp_directory.dart';
import '../model/pnp_link_status.dart';
import '../model/pnp_sign_in_result.dart';

/// Linking the signed-in member's own Pick n Pay account (add-to-pnp
/// ADR-0003): the server names PnP's sign-in page, the member signs in on
/// it, and the code it hands back is relayed for the server to finish. Also
/// where it is unlinked.
///
/// The sign-in page opens only on a tap on *Sign in* — never on opening the
/// screen. One request at a time (`FE-10`); a refusal is held for the banner.
final class PnpLinkController extends ChangeNotifier with ActionFailureHolder {
  PnpLinkController({required PnpDirectory directory}) : _pnp = directory {
    unawaited(_load());
  }

  final PnpDirectory _pnp;

  AsyncState<PnpLinkStatus> _status = const AsyncLoading();
  Uri? _signInPage;
  var _isBusy = false;
  var _isDisposed = false;

  AsyncState<PnpLinkStatus> get status => _status;

  /// PnP's sign-in page while the member is on it; null otherwise.
  Uri? get signInPage => _signInPage;

  bool get isBusy => _isBusy;

  bool get isLinked => switch (_status) {
    AsyncData(:final value) => value.isLinked,
    _ => false,
  };

  Future<void> retry() => _load();

  /// Asks the server for a sign-in page, and shows it.
  Future<void> startSignIn() => _run(() async {
    _signInPage = await _pnp.startLink();
  });

  /// What the sign-in page handed back; answers whether the account is now
  /// linked.
  Future<bool> finishSignIn(PnpSignInResult result) async {
    _signInPage = null;
    final code = result.code;
    final state = result.state;
    if (code == null || state == null) {
      recordFailure(const PnpFailure(PnpProblem.linkCancelled));
      return false;
    }
    await _run(() async {
      _status = AsyncData(await _pnp.completeLink(code: code, state: state));
    });
    return isLinked;
  }

  /// The member closed the sign-in page themselves.
  void closeSignIn() {
    if (_signInPage == null) return;
    _signInPage = null;
    notifyListeners();
  }

  Future<void> unlink() => _run(() async {
    await _pnp.unlink();
    _status = const AsyncData(PnpLinkStatus.unlinked());
  });

  Future<void> _load() async {
    _status = const AsyncLoading();
    notifyListeners();
    AsyncState<PnpLinkStatus> loaded;
    try {
      loaded = AsyncData(await _pnp.linkStatus());
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
    clearFailureQuietly();
    notifyListeners();
    AppFailure? refusal;
    try {
      await action();
    } on AppFailure catch (failure) {
      refusal = failure;
    }
    _isBusy = false;
    if (_isDisposed) return;
    refusal == null ? notifyListeners() : recordFailure(refusal);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
