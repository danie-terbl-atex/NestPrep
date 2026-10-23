import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/plan_week/model/allergen_words.dart';

/// The reviewed not-an-allergen names (recipes ADR-0004): a food whose name
/// holds an allergen word but never the allergen is read past — and nothing
/// else is, because a safe thing missed costs a swap and an unsafe thing let
/// in costs a child (lunch-box ADR-0012).
void main() {
  Set<Allergen> mentioned(String text) => AllergenWords.mentionedIn(text);

  group('names that are not their allergen', () {
    test('butternut is not milk or a tree nut', () {
      expect(mentioned('Roast butternut soup'), isEmpty);
      expect(mentioned('BUTTERNUT'), isEmpty);
    });

    test('nutmeg is not a tree nut', () {
      expect(mentioned('A pinch of nutmeg'), isEmpty);
    });

    test('butter beans, cream of tartar and cream soda are not milk', () {
      expect(mentioned('Butter beans in tomato'), isEmpty);
      expect(mentioned('1 butter bean'), isEmpty);
      expect(mentioned('cream of tartar'), isEmpty);
      expect(mentioned('cream soda'), isEmpty);
    });
  });

  group('the words still caught', () {
    test('butter is milk', () {
      expect(mentioned('Butter'), {Allergen.milk});
    });

    test('peanut butter is peanut and milk', () {
      expect(mentioned('Peanut butter'), {Allergen.peanut, Allergen.milk});
    });

    test('a bare nut is a tree nut', () {
      expect(mentioned('Mixed nut bar'), contains(Allergen.treeNut));
      expect(mentioned('nut'), {Allergen.treeNut});
    });

    test('buttermilk and cream are milk', () {
      expect(mentioned('Buttermilk rusks'), contains(Allergen.milk));
      expect(mentioned('Fresh cream'), {Allergen.milk});
    });

    test('a safe name beside a real one does not hide it', () {
      expect(mentioned('Butternut with butter and nutmeg'), {Allergen.milk});
    });
  });
}
