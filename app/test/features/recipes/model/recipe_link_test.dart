import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_item.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/recipes/model/recipe_link.dart';

/// Which recipe an item opens is read from two separate fields, never
/// guessed from an id (recipes ADR-0002 §5).
void main() {
  LunchItem item({String? recipeId, String? householdRecipeId}) =>
      LunchItem.named(
        id: 'i',
        name: 'Wrap',
        slot: LunchSlot.main,
        allergens: const {},
        addedBy: 'm-sam',
        recipeId: recipeId,
        householdRecipeId: householdRecipeId,
      );

  test('a catalogue recipe and a household recipe are different links', () {
    expect(
      item(recipeId: 'chicken-mayo-wrap').recipeLink,
      const CatalogueRecipeLink('chicken-mayo-wrap'),
    );
    expect(
      item(householdRecipeId: 'ai-0123').recipeLink,
      const HouseholdRecipeLink('ai-0123'),
    );
    expect(
      const CatalogueRecipeLink('x'),
      isNot(equals(const HouseholdRecipeLink('x'))),
    );
  });

  test('most items open no recipe, and an empty id is none', () {
    expect(item().recipeLink, isNull);
    expect(item(recipeId: '', householdRecipeId: '').recipeLink, isNull);
  });

  test('the household link is written only when set, so old items stay as they were', () {
    expect(item().toJson().containsKey('householdRecipeId'), isFalse);
    expect(
      item(householdRecipeId: 'ai-0123').toJson()['householdRecipeId'],
      'ai-0123',
    );
    final read = LunchItem.fromJson({
      ...item(householdRecipeId: 'ai-0123').toJson()..remove('createdAt'),
      'id': 'i',
    });
    expect(read.recipeLink, const HouseholdRecipeLink('ai-0123'));
  });
}
