import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/points_repository.dart';
import '../model/point_entry.dart';

/// One child's recent ledger lines, for the parent's "where did these stars
/// come from" sheet (todos ADR-0003). Lives as long as the sheet.
final class PointHistoryController extends ChangeNotifier {
  PointHistoryController({
    required PointsRepository pointsRepository,
    required this.householdId,
    required this.memberId,
  }) : _points = pointsRepository {
    _subscribe();
  }

  final PointsRepository _points;
  final String householdId;
  final String memberId;

  StreamSubscription<List<PointEntry>>? _subscription;
  AsyncState<List<PointEntry>> _entries = const AsyncLoading();

  AsyncState<List<PointEntry>> get entries => _entries;

  Future<void> retry() async {
    await _cancel();
    _entries = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _points
        .watchEntriesFor(householdId, memberId)
        .listen(
          (value) {
            _entries = AsyncData(value);
            notifyListeners();
          },
          onError: (Object error) {
            _entries = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
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
