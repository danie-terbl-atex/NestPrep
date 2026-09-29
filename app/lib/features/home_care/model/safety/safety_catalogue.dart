import '../product_kind.dart';
import 'precaution.dart';

/// The precautions each kind of product carries — shipped with the app, not
/// editable by a household, and summarised from the sources in
/// `SafetySource` (home-care ADR-0002). The never-mix pairs are
/// `MixingDanger.between`.
///
/// A change here is a change to a safety claim NestPrep makes: it needs its
/// source, and `safety_catalogue_test.dart` pins every pairing that matters.
abstract final class SafetyCatalogue {
  static Set<Precaution> precautionsFor(ProductKind kind) => switch (kind) {
    ProductKind.bleach => const {
      Precaution.onlyWithWater,
      Precaution.gloves,
      Precaution.eyeProtection,
      Precaution.freshAir,
      Precaution.patchTest,
      Precaution.keepFromChildren,
      Precaution.keepFromPets,
    },
    ProductKind.ammonia => const {
      Precaution.gloves,
      Precaution.freshAir,
      Precaution.keepFromChildren,
      Precaution.keepFromPets,
    },
    ProductKind.acidic => const {
      Precaution.gloves,
      Precaution.patchTest,
      Precaution.keepFromChildren,
    },
    ProductKind.alcohol => const {
      Precaution.flammable,
      Precaution.freshAir,
      Precaution.keepFromChildren,
    },
    ProductKind.peroxide => const {
      Precaution.gloves,
      Precaution.eyeProtection,
      Precaution.patchTest,
      Precaution.keepFromChildren,
    },
    ProductKind.ovenCleaner || ProductKind.drainCleaner => const {
      Precaution.corrosive,
      Precaution.gloves,
      Precaution.eyeProtection,
      Precaution.freshAir,
      Precaution.keepFromChildren,
      Precaution.keepFromPets,
    },
    ProductKind.disinfectant => const {
      Precaution.gloves,
      Precaution.freshAir,
      Precaution.keepFromChildren,
      Precaution.keepFromPets,
    },
    ProductKind.polish => const {
      Precaution.flammable,
      Precaution.freshAir,
      Precaution.keepFromChildren,
    },
    ProductKind.allPurpose || ProductKind.floorCleaner => const {
      Precaution.patchTest,
      Precaution.keepFromChildren,
    },
    ProductKind.other => const {Precaution.gloves, Precaution.keepFromChildren},
    ProductKind.dishSoap || ProductKind.bicarbonate => const {},
  };

  /// Whether a kind is one the catalogue treats as dangerous in itself —
  /// what the product list marks with a warning at a glance.
  static bool isHazardous(ProductKind kind) {
    final precautions = precautionsFor(kind);
    return precautions.contains(Precaution.corrosive) ||
        precautions.contains(Precaution.flammable) ||
        kind == ProductKind.bleach ||
        kind == ProductKind.ammonia;
  }
}
