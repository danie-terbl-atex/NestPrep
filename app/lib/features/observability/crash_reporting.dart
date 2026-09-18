import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../app/backend_target.dart';
import '../../shared/log/app_log.dart';

/// Crash and unhandled-error reporting (observability ADR-0001).
///
/// Only *unhandled* errors come here. A refused invite or a rules denial is a
/// handled failure: it becomes copy on a screen (`FE-09`) and a line in the
/// app's own log, never a crash report.
///
/// Nothing sent from here identifies anybody (`ENG-22`). The member id is set
/// as the report's user id because it is the household's own opaque key and
/// says nothing about a person; names, emails and invite codes never are.
abstract final class CrashReporting {
  /// Whether reports actually leave the device. A debug build or an emulator
  /// build sends nothing, so development noise never reaches the dashboard.
  static bool shouldSend(BackendTarget target) =>
      kReleaseMode && target == BackendTarget.cloud;

  /// Installs the two handlers that catch everything Flutter does not.
  /// Called once, from `main()`, after Firebase is initialised.
  static Future<void> install(BackendTarget target) async {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(shouldSend(target));

    // Errors from the framework: a build, a layout, a gesture callback.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _report(() => crashlytics.recordFlutterFatalError(details));
    };

    // Everything else that reaches the engine unhandled, including errors from
    // futures nobody awaited.
    PlatformDispatcher.instance.onError = (error, stack) {
      _report(() => crashlytics.recordError(error, stack, fatal: true));
      return true;
    };
  }

  /// Reports without ever throwing.
  ///
  /// These two handlers *are* the app's last resort: whatever reaches them has
  /// already gone wrong. A report that fails must not add a second failure on
  /// top — and because `PlatformDispatcher.onError` is where an unawaited
  /// future's error lands, a throw from inside it comes straight back to
  /// itself. Nothing is awaited here, so nothing can be awaited badly.
  static void _report(Future<void> Function() send) {
    unawaited(() async {
      try {
        await send();
      } on Object catch (error) {
        AppLog.failure(
          'crashlytics report',
          code: 'report-failed',
          error: error,
        );
      }
    }());
  }

  /// Ties the reports from this device to a member profile, so a crash can be
  /// put next to the household it happened in without naming anybody.
  ///
  /// Its own failure is kept here. The shell calls this without awaiting it —
  /// nothing on screen depends on the answer — so anything thrown would reach
  /// the zone as an unhandled error, which is a crash report about crash
  /// reporting. Whatever is wrong with Crashlytics, the household's week still
  /// has to open.
  static Future<void> setMember(String? memberId) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(memberId ?? '');
    } on Object catch (error) {
      AppLog.failure('crashlytics user', code: 'set-user-failed', error: error);
    }
  }

  /// Throws on purpose, to prove reporting works end to end. Reachable only
  /// from the debug gallery (observability phase 1).
  static void forceACrashForTesting() {
    throw StateError('NestPrep test crash — observability phase 1');
  }
}
