import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// The one typed source of which V2 capabilities this build offers (verdict
/// 003): each can be switched off without a migration, because switching one
/// off only hides its way in — the data stays where it is.
///
/// The values come from `appConfig/featureFlags`, which no client can write.
/// A flag the document does not mention takes its default: **on in a debug
/// build, off in a release**, so a capability ships dark until somebody
/// turns it on in the console, and every developer sees everything.
///
/// Adding a flag is one field, one default and one key — keep this file that
/// small (household ADR-0004 made it; later V2 features add to it).
@immutable
class FeatureFlags {
  const FeatureFlags({required this.coParenting});

  /// Every flag at its default for this build.
  factory FeatureFlags.defaults({bool isDebug = kDebugMode}) =>
      FeatureFlags(coParenting: isDebug);

  /// Reads the stored document, where each flag is a boolean under its own
  /// key. Anything else — absent, a string, a number — is the default, never
  /// a guess (`ENG-09`).
  factory FeatureFlags.fromStored(
    Map<String, Object?>? stored, {
    bool isDebug = kDebugMode,
  }) {
    final defaults = FeatureFlags.defaults(isDebug: isDebug);
    bool read(String key, bool fallback) => switch (stored?[key]) {
      final bool value => value,
      _ => fallback,
    };
    return FeatureFlags(
      coParenting: read(coParentingKey, defaults.coParenting),
    );
  }

  /// A child in two homes: shared schedules and handovers (household
  /// ADR-0004).
  final bool coParenting;

  static const coParentingKey = 'coParenting';

  /// The flags where the widget is, or the defaults when nothing above it
  /// provides any — a widget test that pumps one screen alone gets the debug
  /// defaults, exactly like a developer's build.
  static FeatureFlags of(BuildContext context) =>
      context.watch<FeatureFlags?>() ?? FeatureFlags.defaults();

  @override
  bool operator ==(Object other) =>
      other is FeatureFlags && other.coParenting == coParenting;

  @override
  int get hashCode => coParenting.hashCode;
}
