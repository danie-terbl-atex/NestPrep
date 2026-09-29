import 'feature_flags.dart';

/// Where the flags come from, behind an interface so a test substitutes a
/// fixed set and never pumps a Firebase SDK (foundation ADR-0006).
abstract interface class FeatureFlagSource {
  /// The flags as they are now, and again whenever they change. A read that
  /// fails keeps the defaults rather than taking the app down: a flag is a
  /// convenience, and the rules and Functions are what enforce anything.
  Stream<FeatureFlags> watch();
}
