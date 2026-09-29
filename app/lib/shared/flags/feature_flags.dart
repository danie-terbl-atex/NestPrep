import 'feature_flag.dart';

/// Which V2 capabilities are switched on (foundation ADR-0014).
///
/// A field the document sets wins, either way. A field it does not set — or
/// no document at all, or one that cannot be read — falls back to
/// [defaultOn]: on in a debug build, so a developer and every test see the
/// feature; off in a release build, so V2 ships dark until it is switched on.
class FeatureFlags {
  const FeatureFlags({required this.defaultOn, this.stored = const {}});

  /// Nothing stored yet: every flag at its default.
  const FeatureFlags.defaults({required this.defaultOn}) : stored = const {};

  /// Reads the stored switches from the document's fields, keeping only
  /// booleans under a known name — anything else is as if it were absent.
  factory FeatureFlags.fromFields(
    Map<String, Object?> fields, {
    required bool defaultOn,
  }) => FeatureFlags(
    defaultOn: defaultOn,
    stored: {
      for (final flag in FeatureFlag.values)
        if (fields[flag.field] case final bool value) flag: value,
    },
  );

  final bool defaultOn;
  final Map<FeatureFlag, bool> stored;

  bool isOn(FeatureFlag flag) => stored[flag] ?? defaultOn;
}
