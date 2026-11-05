import '../model/list_photo.dart';

enum ListPhotoSource { camera, photos }

abstract interface class ListPhotoPicker {
  /// The photo, ready to send, or null when the person backed out. Throws
  /// `ListScanFailure(pickerUnavailable)` when nothing would open, and
  /// `ListScanFailure(listPhotoNotSupported)` for a file that is not a photo.
  Future<ListPhoto?> pick(ListPhotoSource source);
}
