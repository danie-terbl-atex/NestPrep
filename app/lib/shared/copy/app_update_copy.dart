/// The prompt that appears once a Shorebird patch has downloaded (foundation
/// ADR-0026). Only Android can open the app again by itself; on iOS the button
/// closes the app and the person opens it.
abstract final class AppUpdateCopy {
  static const title = 'Update installed';
  static const relaunchBody =
      'A newer nestprep is ready. Restart to start using it. Everything you '
      'saved stays as it is.';
  static const closeBody =
      'A newer nestprep is ready. Close nestprep, then open it again to start '
      'using it. Everything you saved stays as it is.';
  static const relaunch = 'Restart nestprep';
  static const close = 'Close nestprep';
}
