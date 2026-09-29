import 'feature_flags.dart';

/// Where the V2 switches come from (foundation ADR-0014): `appConfig/flags`,
/// live, parsed at the edge. Behind an interface so a widget test decides
/// what is switched on without a Firestore.
abstract interface class FeatureFlagSource {
  /// The switches now and whenever they change, each parsed with
  /// [defaultOn] for a field the document does not set.
  Stream<FeatureFlags> watch({required bool defaultOn});
}
