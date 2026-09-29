import '../../features/documents/model/offline_shelf.dart';
import '../failure/app_failure.dart';

/// The words of keeping documents on the phone (documents ADR-0007). Its own
/// file beside `AppCopy`, reached through it (`FE-19`).
abstract final class OfflineCopiesCopy {
  // ---- on a document ----
  static const keep = 'Keep on this phone';
  static const keepNote =
      'Encrypted, behind your phone\'s lock, for when there is no signal.';
  static const saving = 'Saving to this phone';
  static const badge = 'Available offline';
  static const remove = 'Remove from this phone';

  // ---- the list ----
  static const title = 'Offline copies';
  static const entry = 'Offline copies';
  static const entryBody =
      'Documents kept on this phone for when there is '
      'no signal.';
  static const body =
      'Kept on this phone only, encrypted, and opened behind its lock. They '
      'go when you sign out, leave the household, or lose access.';
  static String usage(int count, String size, int limit) =>
      '$count of $limit kept · $size';
  static const emptyTitle = 'Nothing kept on this phone';
  static const emptyBody =
      'Open a document and choose "Keep on this phone" — a medical aid card '
      'for the clinic, say, where there is no signal.';
  static String savedOn(String when) => 'Saved $when';
  static const household = 'Household';
  static const removeAll = 'Remove all from this phone';
  static const removeAllTitle = 'Remove every offline copy?';
  static const removeAllBody =
      'They stay in NestPrep. Only this phone\'s copies go.';
  static const checked =
      'Checked with NestPrep just now. Anything you can no longer open was '
      'removed.';

  static String problem(DocumentProblem problem) => switch (problem) {
    DocumentProblem.offlineLimitReached =>
      'This phone already keeps ${OfflineShelf.maxCopies} documents. Remove '
          'one first.',
    DocumentProblem.offlineCopyUnreadable =>
      'That copy could not be opened, so it was removed. Save it again.',
    DocumentProblem.offlineStorageUnavailable =>
      'This phone would not give NestPrep a safe place for the copy.',
    _ => 'That copy was not saved. Please try again.',
  };
}
