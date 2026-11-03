import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/places_repository.dart';
import '../model/family_place.dart';

final class PlacesController extends ChangeNotifier {
  PlacesController({
    required PlacesRepository placesRepository,
    required this.householdId,
  }) : _repository = placesRepository {
    _subscribe();
  }

  final PlacesRepository _repository;
  final String householdId;
  StreamSubscription<List<FamilyPlace>>? _subscription;
  AsyncState<List<FamilyPlace>> _view = const AsyncLoading();

  AsyncState<List<FamilyPlace>> get view => _view;

  bool get isFull => switch (_view) {
    AsyncData(:final value) => value.length >= FamilyPlace.householdLimit,
    _ => false,
  };

  Future<void> retry() async {
    await _subscription?.cancel();
    _view = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  void _subscribe() {
    _subscription = _repository
        .watchPlaces(householdId)
        .listen(
          (places) {
            _view = AsyncData(
              [...places]..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ),
            );
            notifyListeners();
          },
          onError: (Object error) {
            _view = AsyncFailure(
              error is AppFailure ? error : UnknownFailure(error),
            );
            notifyListeners();
          },
        );
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
