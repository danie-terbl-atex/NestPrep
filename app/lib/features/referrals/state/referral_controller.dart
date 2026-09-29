import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../household/data/invite_sharer.dart';
import '../data/referral_directory.dart';
import '../data/referral_repository.dart';
import '../data/share_referral_code.dart';
import '../model/household_referral.dart';
import '../model/premium_grant.dart';
import '../model/referral_line.dart';
import '../model/referral_overview.dart';

/// *Give a month, get a month* for one household (subscriptions ADR-0002):
/// its code, its referrals and its free months, as three listeners last saw
/// them, and the three things a parent does here — share the code, copy it,
/// and enter another family's.
///
/// The code is made by the server the first time the screen finds none. A
/// refusal from sharing or entering a code is held for the screen
/// (`ActionFailureHolder`); a failed read is the screen's error state.
final class ReferralController extends ChangeNotifier with ActionFailureHolder {
  ReferralController({
    required ReferralRepository referralRepository,
    required ReferralDirectory referralDirectory,
    required InviteSharer inviteSharer,
    required this.householdId,
    DateTime Function()? now,
  }) : _repository = referralRepository,
       _directory = referralDirectory,
       _sharer = inviteSharer,
       _now = now ?? DateTime.now {
    _listen();
  }

  final ReferralRepository _repository;
  final ReferralDirectory _directory;
  final InviteSharer _sharer;
  final DateTime Function() _now;
  final String householdId;

  final _subscriptions = <StreamSubscription<Object?>>[];
  HouseholdReferral? _referral;
  List<ReferralLine>? _lines;
  List<PremiumGrant>? _grants;
  AppFailure? _readFailure;

  bool _isMakingCode = false;
  bool _hasAskedForCode = false;
  AppFailure? _codeFailure;
  bool _isRedeeming = false;
  AppFailure? _redeemFailure;
  bool _shareUnavailable = false;
  bool _isDisposed = false;

  DateTime now() => _now();

  /// Loading until all three listeners have answered; the first failure
  /// among them fails the whole screen, with a retry.
  AsyncState<ReferralOverview> get overview {
    final failure = _readFailure;
    if (failure != null) return AsyncFailure(failure);
    final (referral, lines, grants) = (_referral, _lines, _grants);
    if (referral == null || lines == null || grants == null) {
      return const AsyncLoading();
    }
    return AsyncData(
      ReferralOverview(referral: referral, lines: lines, grants: grants),
    );
  }

  /// The code is being made on the server for the first time.
  bool get isMakingCode => _isMakingCode;

  /// Making the code failed; the code card offers to try again.
  AppFailure? get codeFailure => _codeFailure;

  bool get isRedeeming => _isRedeeming;

  /// Why the last code entered was refused.
  AppFailure? get redeemFailure => _redeemFailure;

  /// The last share sheet would not open; the screen says to copy instead.
  bool get shareUnavailable => _shareUnavailable;

  Future<void> share() => runAction(() async {
    final code = _referral?.code;
    if (code == null) return;
    final outcome = await _sharer.shareReferralCode(code);
    _shareUnavailable = outcome == InviteShareOutcome.unavailable;
    notifyListeners();
  });

  /// Enters another family's code. Answers whether it was accepted; a
  /// refusal is kept as [redeemFailure], which the screen puts on the field
  /// that caused it (`FE-10`).
  Future<bool> redeem(String code) async {
    if (_isRedeeming) return false;
    _isRedeeming = true;
    _redeemFailure = null;
    notifyListeners();
    var accepted = false;
    try {
      await _directory.redeem(householdId: householdId, code: code.trim());
      accepted = true;
    } on AppFailure catch (failure) {
      _redeemFailure = failure;
    }
    _isRedeeming = false;
    if (!_isDisposed) notifyListeners();
    return accepted;
  }

  /// The person has changed what they typed; the old refusal no longer fits.
  void clearRedeemFailure() {
    if (_redeemFailure == null) return;
    _redeemFailure = null;
    notifyListeners();
  }

  /// Asks the server for the code again after a failure.
  Future<void> retryCode() => _makeCode();

  void retry() {
    _stop();
    _referral = null;
    _lines = null;
    _grants = null;
    _readFailure = null;
    notifyListeners();
    _listen();
  }

  void _listen() {
    _subscriptions
      ..add(
        _repository
            .watchReferral(householdId)
            .listen(_onReferral, onError: _onError),
      )
      ..add(
        _repository.watchHistory(householdId).listen((lines) {
          _lines = lines;
          notifyListeners();
        }, onError: _onError),
      )
      ..add(
        _repository.watchGrants(householdId).listen((grants) {
          _grants = grants;
          notifyListeners();
        }, onError: _onError),
      );
  }

  void _onReferral(HouseholdReferral referral) {
    _referral = referral;
    notifyListeners();
    // Asked for once; after a failure only the retry asks again.
    if (referral.code == null && !_hasAskedForCode) {
      _hasAskedForCode = true;
      unawaited(_makeCode());
    }
  }

  /// The server writes the code into the document this screen listens to, so
  /// the answer arrives through the listener; only a failure is kept here.
  Future<void> _makeCode() async {
    if (_isMakingCode) return;
    _isMakingCode = true;
    _codeFailure = null;
    notifyListeners();
    try {
      await _directory.ensureCode(householdId);
    } on AppFailure catch (failure) {
      _codeFailure = failure;
    }
    _isMakingCode = false;
    if (!_isDisposed) notifyListeners();
  }

  void _onError(Object error) {
    _readFailure = error is AppFailure ? error : UnknownFailure(error);
    notifyListeners();
  }

  void _stop() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stop();
    super.dispose();
  }
}
