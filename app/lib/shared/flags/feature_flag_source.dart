import 'feature_flags.dart';

/// Where the switches come from: the `appConfig/flags` document in the app, a
/// fixed value in a test.
abstract interface class FeatureFlagSource {
  /// The flags now and every time they change. It does not fail: a read that
  /// cannot be made leaves the safe defaults in place and says so in the log.
  Stream<FeatureFlags> watch();
}
