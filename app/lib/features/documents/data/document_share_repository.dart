import '../model/document_share.dart';

/// The household's live links, as Firestore holds them (documents ADR-0006).
/// Read-only: only the Functions write a link.
abstract interface class DocumentShareRepository {
  /// Live links — active, ending after [now] — soonest to end first, at most
  /// [limit]. The family sees every link in the household; anybody else only
  /// the ones [viewerUid] made, which is all the rules would give them.
  Stream<List<DocumentShare>> watchLiveShares({
    required String householdId,
    required String viewerUid,
    required bool isFamily,
    required DateTime now,
    int limit = liveShareLimit,
  });

  /// The same cap as `MAX_LIVE_SHARES` on the server (`BE-08`).
  static const liveShareLimit = 25;
}
