import 'dart:async';

import 'package:nestprep/features/diagnostics/data/ping_repository.dart';
import 'package:nestprep/features/diagnostics/model/emulator_ping.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

/// Drives the diagnostics feature from a test: emit lists or errors on the
/// stream, and choose whether `send` succeeds.
final class FakePingRepository implements PingRepository {
  final _controller = StreamController<List<EmulatorPing>>.broadcast();
  final sent = <String>[];
  AppFailure? failSendWith;
  int subscriptions = 0;

  void emit(List<EmulatorPing> pings) => _controller.add(pings);

  void emitError(AppFailure failure) => _controller.addError(failure);

  @override
  Stream<List<EmulatorPing>> watchRecent({int limit = 20}) {
    subscriptions += 1;
    return _controller.stream;
  }

  @override
  Future<void> send({required String sentFrom}) async {
    final failure = failSendWith;
    if (failure != null) throw failure;
    sent.add(sentFrom);
  }

  Future<void> close() => _controller.close();
}
