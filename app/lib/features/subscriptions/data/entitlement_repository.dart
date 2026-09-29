import '../model/entitlement.dart';

/// The household's entitlement, live (subscriptions ADR-0001). Read-only: the
/// rules refuse every client write, because a purchase becomes premium only
/// in a Function after the store has vouched for it.
abstract interface class EntitlementRepository {
  /// [Entitlement.free] while the household has never bought.
  Stream<Entitlement> watchEntitlement(String householdId);
}
