/// One upload, as the screen shows it: what is being added and how far it has
/// got.
///
/// An upload is the one thing in this app a person waits on for longer than a
/// moment, so it has a state of its own rather than an in-flight flag. A
/// progress bar with nothing to say is worse than no progress bar (`FE-08`).
class DocumentUploadState {
  const DocumentUploadState({required this.fileName, required this.fraction});

  /// What is being added, so somebody who picked the wrong file knows before it
  /// finishes.
  final String fileName;

  /// How much of it is stored, from 0 to 1.
  final double fraction;

  DocumentUploadState at(double fraction) =>
      DocumentUploadState(fileName: fileName, fraction: fraction.clamp(0, 1));
}
