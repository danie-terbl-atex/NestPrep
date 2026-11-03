import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/photo_frame_repository.dart';
import '../model/photo_frame.dart';

enum FrameAvailabilityState { hidden, loading, none, some }

final class FrameAvailability extends ChangeNotifier {
  FrameAvailability({
    required PhotoFrameRepository photoFrameRepository,
    required this.householdId,
    required this.isFamily,
  }) : _repository = photoFrameRepository;

  final PhotoFrameRepository _repository;
  final String householdId;
  final bool isFamily;

  StreamSubscription<List<PhotoFrame>>? _subscription;
  var _state = FrameAvailabilityState.hidden;

  FrameAvailabilityState get state => _state;

  void followFlag({required bool framesOn}) {
    final shouldWatch = isFamily && framesOn;
    if (shouldWatch == (_subscription != null)) return;
    if (shouldWatch) {
      _state = FrameAvailabilityState.loading;
      _subscription = _repository
          .watchFrames(householdId)
          .listen(_onFrames, onError: _onError);
    } else {
      _stop();
    }
    notifyListeners();
  }

  void _onFrames(List<PhotoFrame> frames) => _set(
    frames.isEmpty ? FrameAvailabilityState.none : FrameAvailabilityState.some,
  );

  // A list that can't be read says nothing about whether a frame exists, so
  // neither the teaser nor the button is offered on a guess.
  void _onError(Object error) => _set(FrameAvailabilityState.hidden);

  void _set(FrameAvailabilityState state) {
    if (state == _state) return;
    _state = state;
    notifyListeners();
  }

  void _stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _state = FrameAvailabilityState.hidden;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
