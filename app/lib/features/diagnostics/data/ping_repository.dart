import '../model/emulator_ping.dart';

/// What the diagnostics feature needs from storage. Streams are live and
/// bounded; failures surface as `AppFailure` (foundation ADR-0006).
abstract interface class PingRepository {
  Stream<List<EmulatorPing>> watchRecent({int limit = 20});

  Future<void> send({required String sentFrom});
}
