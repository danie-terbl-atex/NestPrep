import 'dart:async';

import 'package:flutter/foundation.dart';

import '../log/app_log.dart';
import 'feature_flag.dart';
import 'feature_flag_source.dart';
import 'feature_flags.dart';

/// The V2 switches for the whole app (foundation ADR-0014) — root-scoped
/// because a switch is read by screens under every route, and a switch that
/// flips while somebody is in the app takes effect at once.
///
/// Until the document answers, and after it fails, every flag is at its
/// default: a read that cannot happen must never turn a V2 feature on in a
/// release build, nor off in a debug one.
final class FeatureFlagsController extends ChangeNotifier {
  FeatureFlagsController({
    required FeatureFlagSource source,
    bool defaultOn = kDebugMode,
  }) : _flags = FeatureFlags.defaults(defaultOn: defaultOn) {
    _subscription = source
        .watch(defaultOn: defaultOn)
        .listen(_onFlags, onError: _onError);
  }

  late final StreamSubscription<FeatureFlags> _subscription;
  FeatureFlags _flags;
  var _hasAnswered = false;

  bool isOn(FeatureFlag flag) => _flags.isOn(flag);

  /// The switches as they stand, for a screen that reads the value rather
  /// than the controller (`context.watch<FeatureFlags>()`).
  FeatureFlags get flags => _flags;

  /// Whether the document has said anything yet. Something that *deletes*
  /// when a switch is off waits for this — the defaults are a guess, and a
  /// release build's guess is "off".
  bool get hasAnswered => _hasAnswered;

  void _onFlags(FeatureFlags flags) {
    _flags = flags;
    _hasAnswered = true;
    notifyListeners();
  }

  void _onError(Object error) {
    // The defaults stand; the switch document being unreadable is logged, not
    // shown — nobody using the app can act on it.
    AppLog.failure('feature flags', code: 'unreadable', error: error);
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
