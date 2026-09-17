import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/ping_repository.dart';
import '../model/emulator_ping.dart';

/// Holds the latest emission of the repository's live stream and the state of
/// the one action the screen offers. It never keeps a copy of server data that
/// the stream does not also hold (`FE-07`).
final class PingListController extends ChangeNotifier {
  PingListController(this._repository, {required this.sentFrom}) {
    _subscribe();
  }

  final PingRepository _repository;
  final String sentFrom;

  AsyncState<List<EmulatorPing>> _pings = const AsyncLoading();
  StreamSubscription<List<EmulatorPing>>? _subscription;
  bool _isSending = false;
  AppFailure? _sendFailure;

  AsyncState<List<EmulatorPing>> get pings => _pings;
  bool get isSending => _isSending;
  AppFailure? get sendFailure => _sendFailure;

  Future<void> retry() async {
    await _subscription?.cancel();
    _pings = const AsyncLoading();
    notifyListeners();
    _subscribe();
  }

  Future<void> sendPing() async {
    if (_isSending) return;
    _isSending = true;
    _sendFailure = null;
    notifyListeners();
    try {
      await _repository.send(sentFrom: sentFrom);
    } on AppFailure catch (failure) {
      _sendFailure = failure;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void _subscribe() {
    _subscription = _repository.watchRecent().listen(
      (pings) {
        _pings = AsyncData(pings);
        notifyListeners();
      },
      onError: (Object error) {
        _pings = AsyncFailure(
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
