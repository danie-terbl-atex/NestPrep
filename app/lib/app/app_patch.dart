import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../shared/log/best_effort.dart';

abstract final class AppPatch {
  static final Future<int?> current = kReleaseMode ? _read() : Future.value();

  /// Off the UI isolate: constructing the updater calls into the engine, which
  /// can block on the lock the launch-time patch check holds.
  static Future<int?> _read() async {
    int? number;
    await bestEffort(
      'shorebird patch',
      code: 'read-patch-failed',
      run: () async => number = await Isolate.run(
        () async => (await ShorebirdUpdater().readCurrentPatch())?.number,
      ),
    );
    return number;
  }
}
