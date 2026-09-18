import '../model/picked_document.dart';

/// Choosing a file off the device. Behind an interface because the platform's
/// picker cannot run in a widget test, and because whether a person picked
/// anything at all is a branch the screen has to handle (`FE-08`).
abstract interface class DocumentPicker {
  /// The file somebody chose, or null when they backed out — which is a
  /// choice, not a failure, and the screen says nothing about it.
  Future<PickedDocument?> pickOne();
}
