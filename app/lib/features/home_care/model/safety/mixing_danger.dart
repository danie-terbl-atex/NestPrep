import '../home_care_product.dart';
import '../product_kind.dart';
import 'safety_source.dart';

/// What two products make, or do, when they meet (home-care ADR-0002).
enum MixingHazard {
  /// Bleach and ammonia: chloramine vapour.
  chloramine(SafetySource.washingtonHealth),

  /// Bleach and an acid: chlorine gas.
  chlorineGas(SafetySource.washingtonHealth),

  /// Bleach and alcohol: chloroform and other poisonous compounds.
  chloroform(SafetySource.washingtonHealth),

  /// Bleach and any other cleaner: bleach is only ever diluted with water.
  bleachWithAnotherCleaner(SafetySource.cdcBleach),

  /// Hydrogen peroxide and an acid such as vinegar: peracetic acid.
  peraceticAcid(SafetySource.poisonControl),

  /// A drain cleaner and anything else, another drain cleaner included.
  drainCleanerReaction(SafetySource.poisonControl);

  const MixingHazard(this.source);

  final SafetySource source;
}

/// Two of a job's products that must never meet, and why.
final class MixingDanger {
  const MixingDanger({
    required this.first,
    required this.second,
    required this.hazard,
  });

  final HomeCareProduct first;
  final HomeCareProduct second;
  final MixingHazard hazard;

  /// The hazard two kinds make together, or null when they are safe to have
  /// in the same job. Order does not matter.
  static MixingHazard? between(ProductKind a, ProductKind b) =>
      _ordered(a, b) ?? _ordered(b, a);

  static MixingHazard? _ordered(ProductKind a, ProductKind b) {
    if (a == ProductKind.drainCleaner) return MixingHazard.drainCleanerReaction;
    if (a == ProductKind.peroxide && b == ProductKind.acidic) {
      return MixingHazard.peraceticAcid;
    }
    if (a != ProductKind.bleach || b == ProductKind.bleach) return null;
    return switch (b) {
      ProductKind.ammonia => MixingHazard.chloramine,
      ProductKind.acidic => MixingHazard.chlorineGas,
      ProductKind.alcohol => MixingHazard.chloroform,
      _ => MixingHazard.bleachWithAnotherCleaner,
    };
  }
}
