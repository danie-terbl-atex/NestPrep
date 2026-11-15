import 'feature_flag.dart';

/// Which V2 capabilities are switched on (foundation ADR-0014).
///
/// A field the document sets wins, either way. A field it does not set — or
/// no document at all, or one that cannot be read — falls back to
/// [defaultOn], which the app sets to on in every build (foundation
/// ADR-0020): only an explicit `false` turns a capability off.
class FeatureFlags {
  const FeatureFlags({
    required this.defaultOn,
    this.stored = const {},
    this.holdsBackWaiting = false,
  });

  /// Nothing stored yet: every flag at its default.
  const FeatureFlags.defaults({
    required this.defaultOn,
    this.holdsBackWaiting = false,
  }) : stored = const {};

  /// Reads the stored switches from the document's fields, keeping only
  /// booleans under a known name — anything else is as if it were absent.
  factory FeatureFlags.fromFields(
    Map<String, Object?> fields, {
    required bool defaultOn,
    bool holdsBackWaiting = false,
  }) => FeatureFlags(
    defaultOn: defaultOn,
    holdsBackWaiting: holdsBackWaiting,
    stored: {
      for (final flag in FeatureFlag.values)
        if (fields[flag.field] case final bool value) flag: value,
    },
  );

  final bool defaultOn;
  final Map<FeatureFlag, bool> stored;

  /// Whether a switch that [FeatureFlag.waitsToGoLive] is off while unset,
  /// as it is in the running app (shops ADR-0002).
  final bool holdsBackWaiting;

  bool isOn(FeatureFlag flag) =>
      stored[flag] ??
      (holdsBackWaiting && flag.waitsToGoLive ? false : defaultOn);
}
