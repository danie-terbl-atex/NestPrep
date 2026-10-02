import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/checkers_shelf.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/lunch_aisle.dart';

/// The shelves of Checkers' lunchbox aisle NestPrep reads (lunch-box
/// ADR-0013): the list compiled in, and `appConfig/lunchAisle` replacing it
/// with only what this build can read.
void main() {
  test('the compiled list fills every compartment and stays in bounds', () {
    const shelves = LunchAisle.checkersKidsLunchbox;
    expect(shelves.length, lessThanOrEqualTo(LunchAisle.shelfLimit));
    expect({for (final shelf in shelves) shelf.slot}, LunchSlot.values.toSet());
    for (final shelf in shelves) {
      expect(shelf.sources, isNotEmpty, reason: shelf.title);
      for (final source in shelf.sources) {
        expect(CheckersShelf.isId(source.id), isTrue, reason: shelf.title);
      }
    }
  });

  test('a shelf reads its list first, then its category', () {
    final shelves = LunchAisle.fromFields({
      'shelves': [
        {
          'title': 'Yoghurt snack time',
          'slot': 'snack',
          'listId': '69d4ebed9cccb04862bcb67f',
          'categoryId': '67075e37ff987811364007b9',
        },
        {
          'title': 'Baby veg',
          'slot': 'veg',
          'categoryId': '67075daeff98781136400728',
        },
      ],
    })!;
    expect(shelves.first.sources, const [
      CheckersShelf.productList('69d4ebed9cccb04862bcb67f'),
      CheckersShelf.displayCategory('67075e37ff987811364007b9'),
    ]);
    expect(shelves.last.slot, LunchSlot.veg);
    expect(shelves.last.sources, const [
      CheckersShelf.displayCategory('67075daeff98781136400728'),
    ]);
  });

  test('an entry this build cannot read is left out', () {
    final shelves = LunchAisle.fromFields({
      'shelves': [
        {'title': 'No source', 'slot': 'snack'},
        {
          'title': 'Drinks',
          'slot': 'drink',
          'listId': '6889d035468baa051e8ba2ee',
        },
        {'title': 'Bad id', 'slot': 'snack', 'listId': 'not-an-id'},
        {'title': '', 'slot': 'snack', 'listId': '6889d035468baa051e8ba2ee'},
        'not a map',
        {
          'title': 'Kept',
          'slot': 'treat',
          'listId': '65bb4f576a79cdbcd449b7b7',
        },
      ],
    })!;
    expect([for (final shelf in shelves) shelf.title], ['Kept']);
  });

  test('a document with nothing readable keeps the compiled list', () {
    expect(LunchAisle.fromFields(const {}), isNull);
    expect(LunchAisle.fromFields(const {'shelves': []}), isNull);
    expect(
      LunchAisle.fromFields(const {
        'shelves': [
          {'title': 'No source', 'slot': 'snack'},
        ],
      }),
      isNull,
    );
  });

  test('at most twelve shelves are read', () {
    final shelves = LunchAisle.fromFields({
      'shelves': [
        for (var i = 0; i < 20; i++)
          {
            'title': 'Shelf $i',
            'slot': 'snack',
            'listId': '69d4ebed9cccb04862bcb67f',
          },
      ],
    })!;
    expect(shelves, hasLength(LunchAisle.shelfLimit));
  });
}
