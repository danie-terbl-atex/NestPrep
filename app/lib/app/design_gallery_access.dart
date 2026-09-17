import 'package:flutter/foundation.dart';

/// Whether this build carries the debug design gallery, and with it the only
/// way to force a crash on purpose.
///
/// Debug builds always do. A release build does **not** — which is a problem for
/// the one thing only a release build can prove, that a crash reaches
/// Crashlytics: collection is off in debug and on any emulator build, so the
/// verification needs a release build *and* a trigger, and until this existed it
/// could only have one of the two (observability ADR-0001).
///
/// So one release build may opt in:
///
///     flutter build apk --release \
///       --dart-define=NESTPREP_BACKEND=cloud \
///       --dart-define=NESTPREP_CRASH_TEST=true
///
/// It is off unless that define says otherwise, so an ordinary release build is
/// unchanged and nothing ships with a crash button in it. The gallery renders no
/// household data and reads nothing, so exposing it exposes no one's data.
abstract final class DesignGalleryAccess {
  static const defineName = 'NESTPREP_CRASH_TEST';

  static const _optedIn = bool.fromEnvironment(defineName);

  /// True in every debug build, and in a release build only when asked for.
  static const isAvailable = kDebugMode || _optedIn;
}
