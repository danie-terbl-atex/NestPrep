/// The two things about documents that Security Rules cannot do, and that are
/// therefore Cloud Functions (foundation ADR-0002, documents ADR-0001).
abstract interface class DocumentDirectory {
  /// Puts this account's household memberships onto its own ID token, and
  /// refreshes the token so the next Storage call carries them.
  ///
  /// Storage rules have no `get()`, so this claim is the only way they can know
  /// who is in which household. It is called before the screen touches Storage
  /// at all, because a person who has just joined should not meet a refusal
  /// they cannot act on.
  Future<void> syncAccess();

  /// Deletes a folder, and refuses one that still holds documents — a rule
  /// cannot count a collection, and a folder deleted out from under its
  /// documents leaves bytes nobody can see and nobody stops paying for.
  Future<void> deleteFolder({
    required String householdId,
    required String folderId,
  });
}
