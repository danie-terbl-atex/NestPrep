import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/entitlement_repository.dart';
import '../model/entitlement.dart';
import '../model/free_child.dart';

/// The household's entitlement, as its listener last saw it — one listener
/// for everything under the household shell, like the household itself
/// (subscriptions ADR-0001, foundation ADR-0006). A screen asks [isPremium];
/// a premium write it guards is refused by the rules either way (`FE-04`).
///
/// Premium ends at an instant with no document changing, so when the
/// household has it this wakes once at that instant and says so.
final class HouseholdEntitlement extends ChangeNotifier {
  HouseholdEntitlement({
    required EntitlementRepository entitlementRepository,
    required this.householdId,
    DateTime Function()? now,
  }) : _repository = entitlementRepository,
       _now = now ?? DateTime.now {
    _listen();
  }

  final EntitlementRepository _repository;
  final DateTime Function() _now;
  final String householdId;

  StreamSubscription<Entitlement>? _subscription;
  StreamSubscription<FreeChild?>? _freeChildSubscription;
  Timer? _lapse;
  AsyncState<Entitlement> _entitlement = const AsyncLoading();
  AsyncState<FreeChild?> _freeChild = const AsyncLoading();

  AsyncState<Entitlement> get entitlement => _entitlement;

  /// Unknown — still loading, or the read failed — is not premium: the
  /// server decides, and a screen that guesses yes would promise a write the
  /// rules refuse.
  bool get isPremium => switch (_entitlement) {
    AsyncData(:final value) => value.isPremiumAt(_now()),
    _ => false,
  };

  DateTime now() => _now();

  /// Whether this household's lunch plans may be written for [childId]
  /// (lunch-box ADR-0009) — the rules' `lunchPlansFor`: every child with
  /// premium; otherwise the child the free tier recorded, or any child while
  /// there is no record. Unknown is no, as for [isPremium].
  bool plansChild(String childId) =>
      isPremium ||
      switch (_freeChild) {
        AsyncData(:final value) => value == null || value.memberId == childId,
        _ => false,
      };

  /// Listens again. The old listener is let go without waiting for it: its
  /// last word has already been heard, and the new one should not queue
  /// behind it.
  void retry() {
    unawaited(_subscription?.cancel());
    unawaited(_freeChildSubscription?.cancel());
    _entitlement = const AsyncLoading();
    _freeChild = const AsyncLoading();
    notifyListeners();
    _listen();
  }

  void _listen() {
    _subscription = _repository
        .watchEntitlement(householdId)
        .listen(_onEntitlement, onError: _onError);
    _freeChildSubscription = _repository
        .watchFreeChild(householdId)
        .listen(_onFreeChild, onError: _onFreeChildError);
  }

  void _onFreeChild(FreeChild? freeChild) {
    _freeChild = AsyncData(freeChild);
    notifyListeners();
  }

  void _onFreeChildError(Object error) {
    _freeChild = AsyncFailure(
      error is AppFailure ? error : UnknownFailure(error),
    );
    notifyListeners();
  }

  void _onEntitlement(Entitlement entitlement) {
    _entitlement = AsyncData(entitlement);
    _wakeAtLapse(entitlement.premiumUntil);
    notifyListeners();
  }

  void _onError(Object error) {
    _entitlement = AsyncFailure(
      error is AppFailure ? error : UnknownFailure(error),
    );
    notifyListeners();
  }

  void _wakeAtLapse(DateTime? until) {
    _lapse?.cancel();
    if (until == null) return;
    final wait = until.difference(_now());
    if (wait.isNegative) return;
    _lapse = Timer(wait, notifyListeners);
  }

  @override
  void dispose() {
    _lapse?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_freeChildSubscription?.cancel());
    super.dispose();
  }
}
