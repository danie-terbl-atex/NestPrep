import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_shelf.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
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
        expect(RetailerShelf.isId(source.id), isTrue, reason: shelf.title);
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
      RetailerShelf.productList('69d4ebed9cccb04862bcb67f'),
      RetailerShelf.displayCategory('67075e37ff987811364007b9'),
    ]);
    expect(shelves.last.slot, LunchSlot.veg);
    expect(shelves.last.sources, const [
      RetailerShelf.displayCategory('67075daeff98781136400728'),
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

  group('Pick n Pay (lunch-box ADR-0026)', () {
    test('its own categories, by code, and no main shelf', () {
      final shelves = LunchAisle.defaultsFor(ProductRetailer.pickNPay);
      expect(shelves.length, lessThanOrEqualTo(LunchAisle.shelfLimit));
      expect(
        shelves.every(
          (shelf) => shelf.sources.single.kind == RetailerShelfKind.pnpCategory,
        ),
        isTrue,
      );
      expect(
        shelves.map((shelf) => shelf.sources.single.id),
        contains('lunch-box-snacks-1664414929'),
      );
      expect(shelves.where((shelf) => shelf.slot == LunchSlot.main), isEmpty);
      expect(
        LunchAisle.defaultsFor(ProductRetailer.checkers),
        LunchAisle.checkersKidsLunchbox,
      );
    });

    test('pnpShelves replaces them; Checkers’ shelves do not', () {
      const fields = {
        'shelves': [
          {
            'title': 'Checkers',
            'slot': 'snack',
            'listId': '69d4ebed9cccb04862bcb67f',
          },
        ],
        'pnpShelves': [
          {
            'title': 'Lunch box',
            'slot': 'snack',
            'categoryCode': 'lunch-box-snacks-1664414929',
          },
          {'title': 'Bad code', 'slot': 'snack', 'categoryCode': 'NOT A CODE'},
        ],
      };
      final pnp = LunchAisle.fromFields(
        fields,
        shop: ProductRetailer.pickNPay,
      )!;
      expect([for (final shelf in pnp) shelf.title], ['Lunch box']);
      expect(
        LunchAisle.fromFields(const {
          'shelves': [],
        }, shop: ProductRetailer.pickNPay),
        isNull,
      );
      expect(LunchAisle.fromFields(fields)!.single.title, 'Checkers');
    });
  });
}
