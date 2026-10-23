import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/family_profiles/model/allergen.dart';
import 'package:nestprep/features/lunch_box/data/lunch_starter_box_document.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/lunch_box/model/lunch_starter_box.dart';
import 'package:nestprep/shared/firestore/parsed_document.dart';

/// `lunchStarterBoxes/{id}` read without a cast: a compartment this build
/// cannot read is dropped from the box and said so; a box with nothing left,
/// no name, or not published is left out whole.
void main() {
  Map<String, Object?> fields(Map<String, Object?> picks) => {
    'name': 'The classic',
    'blurb': 'A wrap and a muffin.',
    'order': 2,
    'status': 'published',
    'version': 1,
    'picks': picks,
  };

  const wrap = {
    'kind': 'recipe',
    'recipeId': 'r-wrap',
    'name': 'Hummus wrap',
    'allergens': ['wheat', 'sesame'],
  };
  const apple = {
    'kind': 'quickPick',
    'seedKey': 'apple',
    'name': 'Apple slices',
    'allergens': <String>[],
  };

  test('a box reads its recipe and its quick pick, by compartment', () {
    final parsed = LunchStarterBoxDocument.parse(
      'b1',
      fields({'main': wrap, 'fruit': apple}),
    );
    final box = (parsed as ValidDocument<LunchStarterBox>).value;
    expect(box.name, 'The classic');
    expect(box.order, 2);
    expect(parsed.dropped, isEmpty);
    final main = box.picks[LunchSlot.main]! as RecipeBoxPick;
    expect(main.recipeId, 'r-wrap');
    expect(main.allergens, {Allergen.wheat, Allergen.sesame});
    expect((box.picks[LunchSlot.fruit]! as QuickBoxPick).seedKey, 'apple');
    expect(box.recipeIds, {'r-wrap'});
  });

  test('a pick of a kind this build does not know is dropped, and said', () {
    final parsed = LunchStarterBoxDocument.parse(
      'b1',
      fields({
        'main': wrap,
        'snack': {
          'kind': 'storeProduct',
          'name': 'Chips',
          'allergens': <String>[],
        },
        'drink': apple,
      }),
    );
    final box = (parsed as ValidDocument<LunchStarterBox>).value;
    expect(box.picks.keys, [LunchSlot.main]);
    expect(parsed.dropped, hasLength(2));
  });

  test(
    'a pick whose allergens cannot be checked is dropped, never trusted',
    () {
      final parsed = LunchStarterBoxDocument.parse(
        'b1',
        fields({
          'main': wrap,
          'fruit': {...apple, 'allergens': 'none'},
          'treat': {
            ...apple,
            'allergens': ['lupin'],
          },
        }),
      );
      final box = (parsed as ValidDocument<LunchStarterBox>).value;
      expect(box.picks.keys, [LunchSlot.main]);
    },
  );

  test('a box with nothing left in it, no name or not published is left '
      'out', () {
    String reason(Map<String, Object?> data) => (LunchStarterBoxDocument.parse(
      'b1',
      data,
    ) as RejectedDocument<LunchStarterBox>).reason;
    expect(
      reason(
        fields({
          'main': {...wrap, 'kind': 'mystery'},
        }),
      ),
      'picks',
    );
    expect(
      reason(
        {
          ...fields({'main': wrap}),
        }..remove('name'),
      ),
      'name',
    );
    expect(
      reason({
        ...fields({'main': wrap}),
        'status': 'retired',
      }),
      'status',
    );
    expect(
      reason({
        ...fields({}),
        'picks': ['main'],
      }),
      'picks',
    );
  });
}
