import 'package:flutter/foundation.dart';

import 'feature_flag.dart';

/// Which capabilities are switched on, as the `appConfig/flags` document last
/// said (`lib/shared/flags/`, foundation ADR-0014). A screen asks [isOn] and
/// shows or hides the way in; it never decides anything the rules do not also
/// enforce (`FE-04`).
///
/// The safe default is **on in a debug build and off in a release build**: a
/// developer sees everything, and a released app shows nothing new until
/// somebody switches it on in the document — so any capability can go dark
/// again without a migration.
///
/// Premium gating is a separate seam: once a household entitlement exists, a
/// premium capability asks both its flag and the entitlement. No entitlement
/// exists on this base yet, so nothing asks.
@immutable
final class FeatureFlags {
  const FeatureFlags._(this._switched, {required this.isDebugBuild});

  /// Nothing switched by the document: every flag at its default.
  const FeatureFlags.defaults({required this.isDebugBuild})
    : _switched = const {};

  /// Every flag on, whatever the build — for tests of a capability itself.
  static const everythingOn = FeatureFlags._({
    FeatureFlag.snapSchoolLetter: true,
    FeatureFlag.mentalLoadView: true,
  }, isDebugBuild: true);

  /// Every flag off, whatever the build — what a released app shows before
  /// anybody switches anything on.
  static const everythingOff = FeatureFlags._({}, isDebugBuild: false);

  /// The document's fields, parsed: a field that is not a bool is ignored
  /// rather than read as "on" (`ENG-09`), and a field this build does not know
  /// is another build's flag.
  factory FeatureFlags.fromDocument(
    Map<String, Object?>? data, {
    required bool isDebugBuild,
  }) => FeatureFlags._({
    for (final flag in FeatureFlag.values)
      if (data?[flag.key] case final bool value) flag: value,
  }, isDebugBuild: isDebugBuild);

  final Map<FeatureFlag, bool> _switched;

  /// What a flag the document does not mention is.
  final bool isDebugBuild;

  bool isOn(FeatureFlag flag) => _switched[flag] ?? isDebugBuild;

  @override
  bool operator ==(Object other) =>
      other is FeatureFlags &&
      other.isDebugBuild == isDebugBuild &&
      mapEquals(other._switched, _switched);

  @override
  int get hashCode => Object.hash(
    isDebugBuild,
    Object.hashAllUnordered([
      for (final entry in _switched.entries) (entry.key, entry.value),
    ]),
  );
}
