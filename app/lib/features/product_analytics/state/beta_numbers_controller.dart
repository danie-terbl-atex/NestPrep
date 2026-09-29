import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../data/beta_numbers_repository.dart';
import '../model/weekly_numbers.dart';

/// The Beta numbers screen's controller: one live read of the recent weeks'
/// totals (product-analytics ADR-0001). There is nothing to write — the numbers
/// are counted by the server, and a client that could change them would make
/// them worthless.
final class BetaNumbersController extends ChangeNotifier {
  BetaNumbersController({
    required BetaNumbersRepository betaNumbersRepository,
    DateTime Function()? now,
  }) : _repository = betaNumbersRepository,
       _now = now ?? DateTime.now {
    _subscribe();
  }

  final BetaNumbersRepository _repository;
  final DateTime Function() _now;

  /// Today on this phone — which week is *this* week, and what "counted
  /// today" means. The numbers themselves are in each family's own week.
  CalendarDate get today => CalendarDate.fromDateTime(_now());

  StreamSubscription<List<WeeklyNumbers>>? _subscription;

  AsyncState<List<WeeklyNumbers>> _weeks = const AsyncLoading();

  /// Newest first.
  AsyncState<List<WeeklyNumbers>> get weeks => _weeks;

  Future<void> retry() async {
    await _cancel();
    _weeks = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _repository.watchRecentWeeks().listen((weeks) {
      _weeks = AsyncData(weeks);
      notifyListeners();
    }, onError: _onError);
  }

  void _onError(Object error) {
    _weeks = AsyncFailure(error is AppFailure ? error : UnknownFailure(error));
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
