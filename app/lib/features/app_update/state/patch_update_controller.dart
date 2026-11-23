import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/log/best_effort.dart';
import '../data/app_restarter.dart';
import '../data/patch_updates.dart';

/// Looks for a Shorebird patch when the app opens and whenever it comes back,
/// and holds the app on the restart card once one has downloaded (foundation
/// ADR-0026). The engine's own launch-time download may still be running, so
/// a patch on its way is looked at again until it lands.
final class PatchUpdateController extends ChangeNotifier {
  PatchUpdateController({
    required this._updates,
    required this._restarter,
    this.downloadPoll = const Duration(seconds: 10),
    this.downloadPolls = 12,
    this.recheckAfter = const Duration(minutes: 15),
  });

  final PatchUpdates _updates;
  final AppRestarter _restarter;
  final Duration downloadPoll;
  final int downloadPolls;
  final Duration recheckAfter;

  bool _restartReady = false;
  bool _canRelaunch = false;
  bool _restarting = false;
  bool _checking = false;
  bool _disposed = false;
  Timer? _poll;
  Timer? _cooldown;

  bool get restartReady => _restartReady;
  bool get canRelaunch => _canRelaunch;
  bool get restarting => _restarting;

  void opened() {
    if (_restartReady || _checking || _poll != null || _cooldown != null) {
      return;
    }
    unawaited(_check(0));
  }

  Future<void> _check(int poll) async {
    _checking = true;
    var readiness = PatchReadiness.current;
    var canRelaunch = false;
    await bestEffort(
      'shorebird update check',
      code: 'patch-check-failed',
      run: () async {
        readiness = await _updates.check();
        if (readiness == PatchReadiness.readyOnRestart) {
          canRelaunch = await _restarter.canRelaunch();
        }
      },
    );
    _checking = false;
    if (_disposed) return;
    switch (readiness) {
      case PatchReadiness.readyOnRestart:
        _canRelaunch = canRelaunch;
        _restartReady = true;
        notifyListeners();
      case PatchReadiness.downloading when poll < downloadPolls:
        _poll = Timer(downloadPoll, () {
          _poll = null;
          unawaited(_check(poll + 1));
        });
      case PatchReadiness.downloading || PatchReadiness.current:
        _cooldown = Timer(recheckAfter, () => _cooldown = null);
    }
  }

  Future<void> restart() async {
    if (_restarting) return;
    _restarting = true;
    notifyListeners();
    await _restarter.restart();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _cooldown?.cancel();
    super.dispose();
  }
}
