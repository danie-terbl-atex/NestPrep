import 'dart:async';

import 'package:nestprep/shared/flags/feature_flag_source.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';
import 'package:nestprep/shared/flags/feature_flags_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// The V2 switches as a test decides them (foundation ADR-0014): emit a
/// document's fields, or fail the read. This file is the one fake of the
/// seam — every feature's harness uses it.
final class FakeFeatureFlagSource implements FeatureFlagSource {
  final _flags = StreamController<Map<String, Object?>>.broadcast();
  bool? lastDefault;

  @override
  Stream<FeatureFlags> watch({required bool defaultOn}) {
    lastDefault = defaultOn;
    return _flags.stream.map(
      (fields) => FeatureFlags.fromFields(fields, defaultOn: defaultOn),
    );
  }

  void emit(Map<String, Object?> fields) => _flags.add(fields);
  void fail(Object error) => _flags.addError(error);
  Future<void> close() => _flags.close();
}

/// The app-wide switches for a pumped screen: every flag at [defaultOn] — on,
/// as in a debug build, unless a test of a switched-off capability says so —
/// until [source] emits.
SingleChildWidget featureFlagsProvider({
  bool defaultOn = true,
  FakeFeatureFlagSource? source,
}) => ChangeNotifierProvider<FeatureFlagsController>(
  create: (_) => FeatureFlagsController(
    source: source ?? FakeFeatureFlagSource(),
    defaultOn: defaultOn,
  ),
);

/// The V2 switches a test chooses: everything on, as a debug build sees it,
/// or everything off, as a release build does before anybody switches
/// anything on.
abstract final class TestFlags {
  static const on = FeatureFlags.defaults(defaultOn: true);
  static const off = FeatureFlags.defaults(defaultOn: false);
}

/// A switchboard that answers [flags] and never changes.
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
