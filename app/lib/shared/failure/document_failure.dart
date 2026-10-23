part of 'app_failure.dart';

// ---- documents (documents ADR-0001, ADR-0002, ADR-0006, ADR-0007) ----

/// Why something about a document did not happen.
///
/// Only the refusals the household vocabulary has no word for. "You are not in
/// this household" and "only an admin can do that" are the same sentence
/// whichever callable said them, so those stay `HouseholdProblem` and this
/// enum does not repeat them (documents ADR-0001).
enum DocumentProblem {
  /// The folder was deleted while somebody was looking at it.
  folderNotFound,

  /// A folder is deleted only once it is empty, because rules cannot count
  /// what is in one and an orphaned document is bytes nobody can see.
  folderNotEmpty,

  /// Past the 20 MiB the rules allow. Refused before the upload starts, so
  /// nobody waits for it.
  fileTooLarge,

  /// Not one of the types a household keeps.
  unsupportedType,

  /// Somebody stopped the upload. Not a fault, but the screen still says what
  /// became of the file.
  uploadCancelled,

  /// The file left the app and no viewer on the device took it. The document
  /// is fine; the phone is the problem, and the person can say so.
  cannotOpen,

  /// A personal vault nobody shared with this person (documents ADR-0002).
  vaultNotShared,

  /// The document was deleted while somebody was opening it.
  documentNotFound,

  /// The scanner could not start or finish on this phone.
  scanFailed,

  /// The person refused the camera, which the scanner needs.
  cameraRefused,

  /// The bytes arrived but are not a PDF or picture the app can draw.
  cannotRender,

  // ---- documents V2: shared links and offline copies (documents ADR-0006,
  // ADR-0007). The first five are reasons `createDocumentShare` and
  // `revokeDocumentShare` give; the last three are the phone's own.

  /// The capability is switched off (foundation ADR-0014).
  featureOff,

  /// Only the family, or a vault's owner, sends a document outside the
  /// household.
  notAllowedToShare,

  /// The shift a link was to end with has already ended.
  shiftNotOpen,

  /// The household already has as many live links as it may.
  tooManyShares,

  /// The link was removed while somebody was stopping it.
  shareNotFound,

  /// This phone already keeps as many offline copies as it may.
  offlineLimitReached,

  /// An offline copy could not be read back — changed on disk, or its key
  /// is gone. It is removed rather than shown.
  offlineCopyUnreadable,

  /// This phone would not give NestPrep a safe place for its key.
  offlineStorageUnavailable,
}

final class DocumentFailure extends AppFailure {
  const DocumentFailure(this.problem);

  final DocumentProblem problem;
}
