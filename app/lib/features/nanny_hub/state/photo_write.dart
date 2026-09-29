import '../model/photo_change.dart';
import 'photo_library.dart';

/// Writes a record whose photo may have changed, in the one safe order
/// (nanny-hub ADR-0003): a picked photo is stored first and the record written
/// pointing at it; a record write that fails takes that photo back out; an
/// old photo the record no longer points at is discarded after. Shared by the
/// hub's edits and pickups (`ENG-02`).
Future<void> writeWithPhoto(
  PhotoLibrary photos,
  PhotoChange change, {
  required String? current,
  required Future<void> Function(String? photoId) write,
}) async {
  final photoId = switch (change) {
    PhotoKept() => current,
    PhotoRemoved() => null,
    PhotoPicked(:final bytes) => await photos.store(bytes),
  };
  try {
    await write(photoId);
  } on Object {
    if (change is PhotoPicked && photoId != null) {
      await photos.discard(photoId);
    }
    rethrow;
  }
  if (current != null && current != photoId) await photos.discard(current);
}
