import 'dart:typed_data';

import '../model/offline_copy.dart';

/// The documents kept on this phone, per account (documents ADR-0007). Every
/// byte and every name is encrypted at rest; this interface only ever hands
/// out what it has decrypted, and only to whoever asks for one account.
abstract interface class OfflineCopyStore {
  /// Every copy [uid] keeps on this phone, newest first.
  Future<List<OfflineCopy>> list(String uid);

  /// Keeps [bytes] as [copy], replacing one already kept under its key.
  Future<void> save(String uid, OfflineCopy copy, Uint8List bytes);

  /// The bytes of [copy]. Refuses with `offlineCopyUnreadable` when they
  /// cannot be decrypted, and `NotFoundFailure` when they are not there.
  Future<Uint8List> read(String uid, OfflineCopy copy);

  /// Removes [copies] of [uid]'s; one not kept is not an error.
  Future<void> remove(String uid, Iterable<OfflineCopy> copies);

  /// Deletes every account's copies and keys but [uid]'s — all of them when
  /// [uid] is null. What sign-out and another account on the phone call.
  Future<void> keepOnly(String? uid);
}
