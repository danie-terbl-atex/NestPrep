import 'dart:typed_data';

/// The hub's photos in Cloud Storage, at `households/{id}/nannyHub/{photoId}`
/// (nanny-hub ADR-0003). A record points at a photo by its id; the bytes are
/// only ever here.
///
/// Storage has no offline cache, so a photo needs a connection where the
/// words beside it do not — which is why a card still reads without its
/// picture.
abstract interface class PhotoStore {
  /// A new object name the rules accept: letters, digits, `_` and `-`.
  String newPhotoId();

  /// Stores already-compressed JPEG bytes under [photoId], stamped with the
  /// uploader's account, which the delete rule checks.
  Future<void> upload({
    required String householdId,
    required String photoId,
    required String uploaderUid,
    required Uint8List jpeg,
  });

  Future<Uint8List> read({
    required String householdId,
    required String photoId,
  });

  Future<void> remove({required String householdId, required String photoId});
}
