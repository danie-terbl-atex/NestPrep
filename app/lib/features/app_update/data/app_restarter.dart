import 'dart:io';

import 'package:flutter/services.dart';

import '../../../shared/log/best_effort.dart';

abstract interface class AppRestarter {
  Future<bool> canRelaunch();

  Future<void> restart();
}

/// Android builds from foundation ADR-0026 on relaunch through
/// `AppRestart.kt`; iOS and older Android builds have no handler, so the
/// app closes and the person opens it again.
final class PlatformAppRestarter implements AppRestarter {
  const PlatformAppRestarter({
    this._exitApp = _exit,
    this.relaunchGrace = const Duration(seconds: 3),
  });

  static const channel = MethodChannel('io.nullstate.nestprep/app_restart');

  final Future<void> Function() _exitApp;
  final Duration relaunchGrace;

  @override
  Future<bool> canRelaunch() async {
    try {
      return await channel.invokeMethod<bool>('canRelaunch') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> restart() async {
    if (await canRelaunch()) {
      final failed = await bestEffort(
        'relaunch the app',
        code: 'relaunch-failed',
        run: () => channel.invokeMethod<void>('relaunch'),
      );
      // The relaunch kills this process; still being here means it did not.
      if (failed == null) await Future<void>.delayed(relaunchGrace);
    }
    await _exitApp();
  }
}

Future<void> _exit() async => exit(0);
