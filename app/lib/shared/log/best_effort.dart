import 'app_log.dart';

/// Runs something whose failure must not become the caller's problem.
///
/// A handful of operations are genuinely best-effort: telling Crashlytics which
/// member profile is using the device, or sending a crash report at all. Nothing
/// on screen depends on them, and the *only* correct response to one failing is
/// a log line — a household's week still has to open when Crashlytics is having
/// a bad day.
///
/// This is not a licence to swallow errors (`ENG-10`). It is the opposite: the
/// swallow is named, in one place, with the log line it must produce, so that a
/// bare `try {} catch {}` somewhere else has no excuse. Anything a person is
/// waiting on belongs in `AsyncState` or `ActionFailureHolder` instead, where
/// the failure reaches a screen.
///
/// Reporting is also the one place a thrown error can come back to itself:
/// `PlatformDispatcher.onError` is where an unawaited future's error lands, so a
/// report that throws inside that handler is handed straight back to the handler
/// that was already reporting. Nothing here is awaited by the reporter, and
/// nothing here escapes.
///
/// Returns the error it swallowed, or null when [run] completed. Callers are
/// free to ignore it; a test is not.
Future<Object?> bestEffort(
  String operation, {
  required String code,
  required Future<void> Function() run,
}) async {
  try {
    await run();
    return null;
  } on Object catch (error) {
    AppLog.failure(operation, code: code, error: error);
    return error;
  }
}
