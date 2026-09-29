/// Makes sure Firestore's own cache holds what a carer needs without a
/// signal — the emergency sheet, every child card with its allergies and
/// medication, the house guide, the rules, the checklists and who may collect
/// each child — by reading each of them from the server once (nanny-hub
/// ADR-0007). The listeners then answer from that cache when the signal goes.
abstract interface class CacheWarmer {
  /// Reads everything [request] covers from the server, and answers the ids
  /// of the photos those records point at, for the offline shelf to keep.
  /// Throws the `AppFailure` that stopped it — `UnavailableFailure` when
  /// there is no signal.
  Future<Set<String>> warm(WarmRequest request);
}

/// What to read: the hub always; the children's profiles and medication only
/// where family profiles' grants let the viewer read them (nanny-hub
/// ADR-0003), because a read the rules refuse is not a warm cache.
typedef WarmRequest = ({
  String householdId,
  bool readsProfiles,
  List<String> healthOf,
});
