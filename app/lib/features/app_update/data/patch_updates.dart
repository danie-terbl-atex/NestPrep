import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

enum PatchReadiness { current, downloading, readyOnRestart }

abstract interface class PatchUpdates {
  Future<PatchReadiness> check();
}

final class ShorebirdPatchUpdates implements PatchUpdates {
  const ShorebirdPatchUpdates();

  /// Off the UI isolate: the updater's calls block on the lock the engine's
  /// own launch-time download holds.
  @override
  Future<PatchReadiness> check() async {
    if (!kReleaseMode) return PatchReadiness.current;
    return Isolate.run(_checkAndDownload);
  }
}

Future<PatchReadiness> _checkAndDownload() async {
  final updater = ShorebirdUpdater();
  var status = await updater.checkForUpdate();
  if (status == UpdateStatus.outdated) {
    await updater.update();
    status = await updater.checkForUpdate();
  }
  return switch (status) {
    UpdateStatus.restartRequired => PatchReadiness.readyOnRestart,
    UpdateStatus.outdated => PatchReadiness.downloading,
    UpdateStatus.upToDate || UpdateStatus.unavailable => PatchReadiness.current,
  };
}
