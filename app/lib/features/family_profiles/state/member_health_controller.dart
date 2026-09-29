import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/state/action_failure.dart';
import '../data/family_profile_repository.dart';
import '../model/medication.dart';
import '../model/member_health.dart';

/// One person's medication, on their profile screen.
///
/// A viewer who may not see it (a helper, until household phase 2 grants it)
/// never opens the listener at all: the rules would refuse it, and asking in
/// order to be refused is an error state for something that is not an error.
/// The screen says whose it is to see instead (family-profiles ADR-0001).
final class MemberHealthController extends ChangeNotifier
    with ActionFailureHolder {
  MemberHealthController({
    required FamilyProfileRepository familyProfileRepository,
    required this.householdId,
    required this.memberId,
    required this.isVisible,
  }) : _repository = familyProfileRepository {
    if (isVisible) _start();
  }

  final FamilyProfileRepository _repository;
  final String householdId;
  final String memberId;

  /// Whether the viewer may read this person's medication at all.
  final bool isVisible;

  StreamSubscription<MemberHealth>? _subscription;
  AsyncState<MemberHealth> _health = const AsyncLoading();

  AsyncState<MemberHealth> get health => _health;

  Future<void> retry() async {
    if (!isVisible) return;
    await _cancel();
    _health = const AsyncLoading();
    notifyListeners();
    _start();
  }

  /// Adds a medicine when [medicationId] is null, or replaces that one.
  Future<void> saveMedication(Medication medication, {String? medicationId}) {
    final name = medication.name.trim();
    if (name.isEmpty) return Future.value();
    return runAction(
      () => _repository.saveMedication(
        householdId: householdId,
        memberId: memberId,
        medicationId: medicationId,
        medication: medication.copyWith(
          name: name,
          dose: _tidy(medication.dose),
          note: _tidy(medication.note),
          times: medication.timesInOrder,
        ),
      ),
    );
  }

  Future<void> removeMedication(String medicationId) => runAction(
    () => _repository.removeMedication(
      householdId: householdId,
      memberId: memberId,
      medicationId: medicationId,
    ),
  );

  static String? _tidy(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void _start() {
    _subscription = _repository
        .watchHealth(householdId: householdId, memberId: memberId)
        .listen((health) {
          _health = AsyncData(health);
          notifyListeners();
        }, onError: _onError);
  }

  void _onError(Object error) {
    _health = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
    notifyListeners();
  }

  Future<void> _cancel() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    unawaited(_cancel());
    super.dispose();
  }
}
