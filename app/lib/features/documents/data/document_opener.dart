/// Handing a file to whatever on the device can show it.
///
/// Behind an interface because a widget test has no browser and no viewer, and
/// because "the device could not open it" is a state the screen has to say
/// something true about (`FE-08`).
abstract interface class DocumentOpener {
  /// Opens [link] outside NestPrep. Returns false when nothing on the device
  /// would take it.
  Future<bool> open(Uri link);
}
