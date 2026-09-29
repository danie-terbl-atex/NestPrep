import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/entitlement_repository.dart';
import '../model/entitlement.dart';

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
  Timer? _lapse;
  AsyncState<Entitlement> _entitlement = const AsyncLoading();

  AsyncState<Entitlement> get entitlement => _entitlement;

  /// Unknown — still loading, or the read failed — is not premium: the
  /// server decides, and a screen that guesses yes would promise a write the
  /// rules refuse.
  bool get isPremium => switch (_entitlement) {
    AsyncData(:final value) => value.isPremiumAt(_now()),
    _ => false,
  };

  DateTime now() => _now();

  /// Listens again. The old listener is let go without waiting for it: its
  /// last word has already been heard, and the new one should not queue
  /// behind it.
  void retry() {
    unawaited(_subscription?.cancel());
    _entitlement = const AsyncLoading();
    notifyListeners();
    _listen();
  }

  void _listen() {
    _subscription = _repository
        .watchEntitlement(householdId)
        .listen(_onEntitlement, onError: _onError);
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
    super.dispose();
  }
}
