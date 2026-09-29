import '../model/share_request.dart';
import '../model/shared_link.dart';

/// Making and stopping shared links — Cloud Functions, because a rule cannot
/// mint a secret, hash it, or serve a document to somebody with no account
/// (documents ADR-0006).
abstract interface class DocumentShareDirectory {
  /// Makes the link and answers it, once. Refuses with a `DocumentProblem`:
  /// `notAllowedToShare`, `shiftNotOpen`, `tooManyShares`, `featureOff`,
  /// `documentNotFound`.
  Future<SharedLink> create(ShareRequest request);

  /// Stops a link now. Stopping one that already ended is not an error.
  Future<void> revoke({required String householdId, required String shareId});
}
