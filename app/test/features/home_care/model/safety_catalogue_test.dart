import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/home_care/model/home_care_product.dart';
import 'package:nestprep/features/home_care/model/product_kind.dart';
import 'package:nestprep/features/home_care/model/safety/job_safety.dart';
import 'package:nestprep/features/home_care/model/safety/mixing_danger.dart';
import 'package:nestprep/features/home_care/model/safety/precaution.dart';
import 'package:nestprep/features/home_care/model/safety/safety_catalogue.dart';
import 'package:nestprep/features/home_care/model/safety/safety_source.dart';
import 'package:nestprep/shared/copy/app_copy.dart';

/// The safety catalogue is a claim NestPrep makes about chemistry
/// (home-care ADR-0002). Every pairing that hurts somebody is pinned here, so
/// a change to the catalogue that loses one fails the build rather than
/// reaching a helper.
void main() {
  HomeCareProduct product(ProductKind kind, {String? name}) => HomeCareProduct(
    id: kind.name,
    name: name ?? kind.name,
    kind: kind,
    createdBy: 'm1',
  );

  group('what must never meet', () {
    final pairs = {
      (ProductKind.bleach, ProductKind.ammonia): MixingHazard.chloramine,
      (ProductKind.bleach, ProductKind.acidic): MixingHazard.chlorineGas,
      (ProductKind.bleach, ProductKind.alcohol): MixingHazard.chloroform,
      (ProductKind.peroxide, ProductKind.acidic): MixingHazard.peraceticAcid,
      (ProductKind.bleach, ProductKind.allPurpose):
          MixingHazard.bleachWithAnotherCleaner,
      (ProductKind.bleach, ProductKind.disinfectant):
          MixingHazard.bleachWithAnotherCleaner,
      (ProductKind.bleach, ProductKind.ovenCleaner):
          MixingHazard.bleachWithAnotherCleaner,
      (ProductKind.drainCleaner, ProductKind.dishSoap):
          MixingHazard.drainCleanerReaction,
      (ProductKind.drainCleaner, ProductKind.drainCleaner):
          MixingHazard.drainCleanerReaction,
    };

    for (final MapEntry(key: (a, b), value: hazard) in pairs.entries) {
      test(
        '${a.name} and ${b.name} is ${hazard.name}, whichever way round',
        () {
          expect(MixingDanger.between(a, b), hazard);
          expect(MixingDanger.between(b, a), hazard);
        },
      );
    }

    test('two bleaches, or soap and bicarbonate, are not a hazard', () {
      expect(
        MixingDanger.between(ProductKind.bleach, ProductKind.bleach),
        isNull,
      );
      expect(
        MixingDanger.between(ProductKind.dishSoap, ProductKind.bicarbonate),
        isNull,
      );
      expect(
        MixingDanger.between(ProductKind.allPurpose, ProductKind.floorCleaner),
        isNull,
      );
    });

    test('every hazard names the source it comes from', () {
      for (final hazard in MixingHazard.values) {
        expect(SafetySource.values, contains(hazard.source));
        expect(HomeCareSafetyCopy.hazard(hazard), isNotEmpty);
      }
    });
  });

  group('a job’s safety', () {
    test('puts every never-mix pair among its products first', () {
      final safety = JobSafety.of([
        product(ProductKind.bleach, name: 'Jik'),
        product(ProductKind.ammonia, name: 'Window spray'),
        product(ProductKind.dishSoap, name: 'Sunlight'),
      ]);
      expect(safety.hasDangers, isTrue);
      expect(
        [
          for (final danger in safety.dangers)
            (danger.first.name, danger.second.name, danger.hazard),
        ],
        [
          ('Jik', 'Window spray', MixingHazard.chloramine),
          ('Jik', 'Sunlight', MixingHazard.bleachWithAnotherCleaner),
        ],
      );
    });

    test('lists each precaution once, in reading order', () {
      final safety = JobSafety.of([
        product(ProductKind.ovenCleaner),
        product(ProductKind.bleach),
      ]);
      expect(safety.precautions.first, Precaution.corrosive);
      expect(safety.precautions.toSet().length, safety.precautions.length);
      expect(
        safety.precautions,
        orderedEquals([
          for (final precaution in Precaution.values)
            if (safety.precautions.contains(precaution)) precaution,
        ]),
      );
    });

    test('adds the household’s own cautions to what the kind says', () {
      const soap = HomeCareProduct(
        id: 'soap',
        name: 'Soap',
        kind: ProductKind.dishSoap,
        keepFromChildren: true,
        keepFromPets: true,
        createdBy: 'm1',
      );
      expect(SafetyCatalogue.precautionsFor(ProductKind.dishSoap), isEmpty);
      expect(JobSafety.of([soap]).precautions, [
        Precaution.keepFromChildren,
        Precaution.keepFromPets,
      ]);
    });

    test('a job with no products has nothing to warn about', () {
      final safety = JobSafety.of(const []);
      expect(safety.hasDangers, isFalse);
      expect(safety.precautions, isEmpty);
    });
  });

  group('the catalogue', () {
    test('bleach is only ever with water, with gloves and fresh air', () {
      expect(
        SafetyCatalogue.precautionsFor(ProductKind.bleach),
        containsAll([
          Precaution.onlyWithWater,
          Precaution.gloves,
          Precaution.freshAir,
        ]),
      );
    });

    test('oven and drain cleaners are corrosive, and need eye protection', () {
      for (final kind in [ProductKind.ovenCleaner, ProductKind.drainCleaner]) {
        expect(
          SafetyCatalogue.precautionsFor(kind),
          containsAll([Precaution.corrosive, Precaution.eyeProtection]),
        );
        expect(SafetyCatalogue.isHazardous(kind), isTrue);
      }
    });

    test('alcohol and aerosols are flammable', () {
      for (final kind in [ProductKind.alcohol, ProductKind.polish]) {
        expect(
          SafetyCatalogue.precautionsFor(kind),
          contains(Precaution.flammable),
        );
      }
    });

    test('washing-up liquid is not marked as dangerous', () {
      expect(SafetyCatalogue.isHazardous(ProductKind.dishSoap), isFalse);
    });

    test('every kind has a name and an example a parent can recognise', () {
      for (final kind in ProductKind.values) {
        expect(HomeCareLibraryCopy.productKindName(kind), isNotEmpty);
        expect(HomeCareLibraryCopy.productKindExamples(kind), isNotEmpty);
      }
    });

    test('every precaution and source has words', () {
      for (final precaution in Precaution.values) {
        expect(HomeCareSafetyCopy.precaution(precaution), isNotEmpty);
        expect(HomeCareSafetyCopy.precautionWhy(precaution), isNotEmpty);
      }
      for (final source in SafetySource.values) {
        expect(HomeCareSafetyCopy.sourceName(source), isNotEmpty);
        expect(HomeCareSafetyCopy.sourceSays(source), isNotEmpty);
      }
    });

    test('the accident line gives the helpline number its source gives', () {
      final number = RegExp(r'0861 555 777');
      expect(HomeCareSafetyCopy.accidentBody, matches(number));
      expect(
        HomeCareSafetyCopy.sourceSays(SafetySource.poisonsHelpline),
        matches(number),
      );
    });
  });
}
