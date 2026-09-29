import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../../accounts/model/kid_identity.dart';
import '../../kid_accounts/model/kid_areas.dart';
import '../../kid_accounts/model/kid_day.dart';
import '../data/points_repository.dart';
import '../data/reward_repository.dart';
import '../model/kid_points.dart';
import '../model/point_balance.dart';
import '../model/point_claim.dart';
import '../model/reward.dart';
import '../model/reward_request.dart';

/// A child's stars on their own device (todos ADR-0003): their balance, what
/// their recent jobs' claims say, the shelf, and what they have asked for.
///
/// It follows the kid home: the reads open only once the home knows the
/// household's today and the grant shows jobs (accounts ADR-0004), and close
/// when a parent narrows it. A refused read here is that narrowing arriving
/// first, and hides the stars rather than showing an error.
///
/// When the balance rises while the child is looking, [points] carries a
/// [StarCelebration] — the card's burst and its "you earned" line.
final class KidPointsController extends ChangeNotifier
    with ActionFailureHolder {
  KidPointsController({
    required PointsRepository pointsRepository,
    required RewardRepository rewardRepository,
    required this.identity,
  }) : _points = pointsRepository,
       _rewards = rewardRepository;

  final PointsRepository _points;
  final RewardRepository _rewards;
  final KidIdentity identity;

  final _subscriptions = <StreamSubscription<Object?>>[];
  final _asking = <String>{};
  KidAreas? _areas;
  CalendarDate? _today;
  bool _disposed = false;

  PointBalance? _balance;
  List<PointClaim>? _claims;
  List<Reward>? _shelf;
  List<RewardRequest>? _requests;
  int? _lastStars;
  int _celebrations = 0;
  StarCelebration? _celebration;

  AsyncState<KidPoints>? _state;

  /// Null while the stars are not shown at all — the grant hides jobs, or the
  /// home has not yet said what today is.
  AsyncState<KidPoints>? get points => _state;

  /// Whether a request for [reward] is on its way (`FE-10`).
  bool isAsking(Reward reward) => _asking.contains(reward.id);

  /// What the home can see: the grant, and the household's today.
  void follow(KidAreas? areas, CalendarDate? today) {
    final show = areas != null && areas.chores && today != null;
    final wasShowing = _areas?.chores == true && _today != null;
    final changed =
        show != wasShowing ||
        (show && (_today != today || _areas?.canTick != areas.canTick));
    _areas = areas;
    _today = today;
    if (!changed) return;
    unawaited(_reopen(show: show));
  }

  Future<void> retry() => _reopen(show: _state != null);

  /// Asks for [reward], as this child and for this child — the only request
  /// the rules take from a kid device.
  Future<void> ask(Reward reward) async {
    if (!_asking.add(reward.id)) return;
    notifyListeners();
    try {
      await runAction(
        () => _rewards.requestReward(
          householdId: identity.householdId,
          rewardId: reward.id,
          memberId: identity.memberId,
          requestedBy: identity.memberId,
        ),
      );
    } finally {
      _asking.remove(reward.id);
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _reopen({required bool show}) async {
    await _cancel();
    _balance = null;
    _claims = null;
    _shelf = null;
    _requests = null;
    _lastStars = null;
    _celebration = null;
    _state = show ? const AsyncLoading() : null;
    if (!_disposed) notifyListeners();
    final today = _today;
    if (show && today != null) _subscribe(today);
  }

  void _subscribe(CalendarDate today) {
    final (householdId, memberId) = (identity.householdId, identity.memberId);
    _listen(_points.watchBalance(householdId, memberId), (value) {
      _noticeStars(value.balance);
      _balance = value;
    });
    _listen(
      _points.watchClaimsFor(
        householdId,
        memberId,
        from: KidDay.windowStartFor(today),
      ),
      (value) => _claims = value,
    );
    _listen(_rewards.watchRewards(householdId), (value) => _shelf = value);
    _listen(
      _rewards.watchRequestsFor(householdId, memberId),
      (value) => _requests = value,
    );
  }

  /// A rise while the child is looking is worth a celebration; the first
  /// emission, and spending, are not.
  void _noticeStars(int stars) {
    final before = _lastStars;
    _lastStars = stars;
    if (before == null || stars <= before) return;
    _celebrations += 1;
    _celebration = StarCelebration(
      gained: stars - before,
      sequence: _celebrations,
    );
  }

  void _listen<T>(Stream<T> stream, void Function(T value) onValue) {
    _subscriptions.add(
      stream.listen(
        (value) {
          onValue(value);
          _publish();
        },
        onError: (Object error) {
          final failure = error is AppFailure ? error : UnknownFailure(error);
          // The grant narrowed before the profile said so: hide, never error.
          _state = failure is PermissionDeniedFailure
              ? null
              : AsyncFailure(failure);
          unawaited(_cancel());
          notifyListeners();
        },
      ),
    );
  }

  void _publish() {
    final (balance, claims, shelf, requests, today) = (
      _balance,
      _claims,
      _shelf,
      _requests,
      _today,
    );
    if (balance == null ||
        claims == null ||
        shelf == null ||
        requests == null ||
        today == null) {
      return;
    }
    _state = AsyncData(
      KidPoints(
        balance: balance,
        claims: claims,
        rewards: shelf,
        requests: requests,
        today: today,
        canSpend: _areas?.canTick ?? false,
        celebration: _celebration,
      ),
    );
    notifyListeners();
  }

  Future<void> _cancel() async {
    final open = [..._subscriptions];
    _subscriptions.clear();
    for (final subscription in open) {
      await subscription.cancel();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_cancel());
    super.dispose();
  }
}
