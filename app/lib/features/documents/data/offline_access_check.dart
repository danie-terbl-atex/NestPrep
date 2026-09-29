import '../model/offline_copy.dart';

/// Whether this person may still open the document a copy was taken from
/// (documents ADR-0007), asked of the server rather than of any cache — the
/// whole point is to notice a grant revoked while the phone was away.
abstract interface class OfflineAccessCheck {
  Future<OfflineAccess> check(OfflineCopy copy);
}

enum OfflineAccess {
  /// The server still lets this person read it.
  kept,

  /// Refused, or gone: the copy must go too.
  lost,

  /// No answer — offline, most likely. The copy stays; that is what it is for.
  unknown,
}
