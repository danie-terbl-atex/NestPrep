import 'dart:typed_data';

/// Where a photo comes from: the camera, for the carer mid-shift, or the
/// phone's library, for a parent building the house guide.
enum PhotoSource { camera, library }

/// The platform's own camera and photo library, behind an interface because a
/// widget test has neither (nanny-hub ADR-0003).
abstract interface class PhotoPicker {
  /// The picked photo's bytes as the phone gave them, or null when the person
  /// backed out. Throws `NannyHubFailure(cameraUnavailable)` when the camera
  /// or library would not open.
  Future<Uint8List?> pick(PhotoSource source);
}
