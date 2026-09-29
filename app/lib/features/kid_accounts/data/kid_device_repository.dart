import '../model/kid_device.dart';

/// The household's signed-in kid devices, for the admins who can end them
/// (accounts ADR-0003). Read-only: every write is a callable.
abstract interface class KidDeviceRepository {
  /// Every kid device in the household, live. Admin only — the rules refuse
  /// anybody else.
  Stream<List<KidDevice>> watchDevices(String householdId);

  /// Five a profile and a household of a few children; this cap exists so a
  /// bug cannot make the read unbounded (`BE-08`).
  static const deviceLimit = 50;
}
