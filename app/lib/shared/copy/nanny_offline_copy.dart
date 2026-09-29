/// Works-offline words (`FE-19`, nanny-hub ADR-0007): whether the emergency
/// sheet and the child cards are on this phone for when the signal goes.
abstract final class NannyOfflineCopy {
  static String syncedOn(String day, String time) => '$day $time';
  static const saved = 'Saved for offline';
  static String lastSynced(String when) => 'Last synced $when';
  static const saving = 'Saving for offline…';
  static const notSaved = 'Not saved for offline yet';
  static const notSavedBody = 'Tap to save it now, while you have signal.';
  static const noSignal = 'No signal';
  static String showingSaved(String when) =>
      'Showing what was saved at $when. Tap to try again.';
  static const nothingSaved =
      'Nothing is saved on this phone yet. Tap to try again.';
  static const failedKeeping = 'Could not update the offline copy';
  static const failed = 'Could not save for offline';
  static const tapToRetry = 'Tap to try again.';
}
