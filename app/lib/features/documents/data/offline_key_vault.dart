/// Where the key that seals an account's offline copies lives (documents
/// ADR-0007): one 32-byte key per account per phone, in the platform's
/// keystore, never synced or backed up.
abstract interface class OfflineKeyVault {
  /// The account's key, made the first time it is asked for. Refuses with
  /// `DocumentProblem.offlineStorageUnavailable` when the keystore will not
  /// hold one.
  Future<List<int>> keyFor(String uid);

  /// The accounts that have a key on this phone.
  Future<Set<String>> accounts();

  /// Forgets an account's key; whatever it sealed is unreadable from then on.
  Future<void> forget(String uid);
}
