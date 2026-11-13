import 'dart:typed_data';

abstract interface class AvatarPhotoStore {
  Uint8List? kept({
    required String householdId,
    required String memberId,
    required String hash,
  });

  Future<Uint8List?> read({
    required String householdId,
    required String memberId,
    required String hash,
  });

  Uint8List? keptAt(String path);

  Future<Uint8List?> readAt(String path);

  Future<void> uploadReference({
    required String householdId,
    required String memberId,
    required String inboxId,
    required String uploaderUid,
    required Uint8List bytes,
  });

  Future<void> upload({
    required String householdId,
    required String memberId,
    required String hash,
    required String uploaderUid,
    required Uint8List bytes,
  });
}
