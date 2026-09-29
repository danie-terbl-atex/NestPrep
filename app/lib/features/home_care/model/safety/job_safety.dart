import '../home_care_product.dart';
import 'mixing_danger.dart';
import 'precaution.dart';
import 'safety_catalogue.dart';

/// Everything a helper must know before starting a job, worked out from its
/// products — never stored, so a correction to the catalogue reaches every
/// job at once (home-care ADR-0002).
final class JobSafety {
  const JobSafety._({required this.dangers, required this.precautions});

  factory JobSafety.of(List<HomeCareProduct> products) {
    final dangers = <MixingDanger>[];
    for (var i = 0; i < products.length; i++) {
      for (var j = i + 1; j < products.length; j++) {
        final hazard = MixingDanger.between(products[i].kind, products[j].kind);
        if (hazard == null) continue;
        dangers.add(
          MixingDanger(first: products[i], second: products[j], hazard: hazard),
        );
      }
    }
    final precautions = <Precaution>{
      for (final product in products) ...[
        ...SafetyCatalogue.precautionsFor(product.kind),
        if (product.keepFromChildren) Precaution.keepFromChildren,
        if (product.keepFromPets) Precaution.keepFromPets,
      ],
    };
    return JobSafety._(
      dangers: dangers,
      precautions: Precaution.values.where(precautions.contains).toList(),
    );
  }

  /// The pairs in this job that must never meet — shown first and loudest.
  final List<MixingDanger> dangers;

  /// What to wear, open and watch for, in reading order.
  final List<Precaution> precautions;

  bool get hasDangers => dangers.isNotEmpty;
}
