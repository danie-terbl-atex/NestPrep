import 'package:nestprep/shared/flags/feature_flag_source.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';

/// The V2 switches a test chooses (foundation ADR-0014): everything on, as a
/// debug build sees it, or everything off, as a release build does before
/// anybody switches anything on.
abstract final class TestFlags {
  static const on = FeatureFlags.defaults(defaultOn: true);
  static const off = FeatureFlags.defaults(defaultOn: false);
}

/// A switchboard that answers [flags] and never changes — nanny-hub's tests'
/// stand-in for `appConfig/flags`.
final class FixedFeatureFlagSource implements FeatureFlagSource {
  const FixedFeatureFlagSource(this.flags);

  final FeatureFlags flags;

  @override
  Stream<FeatureFlags> watch({required bool defaultOn}) => Stream.value(flags);
}

/// The app's flag controller over [flags], for a test to provide above the
/// screens it pumps.
FeatureFlagsController testFlagsController(FeatureFlags flags) =>
    FeatureFlagsController(
      source: FixedFeatureFlagSource(flags),
      defaultOn: flags.defaultOn,
    );
