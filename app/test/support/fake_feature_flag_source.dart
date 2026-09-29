import 'dart:async';

import 'package:nestprep/shared/flags/feature_flag_source.dart';
import 'package:nestprep/shared/flags/feature_flags.dart';

/// The V2 switches, driven by hand (foundation ADR-0014): nothing answers
/// until a test emits, so a screen shows the build default first.
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
