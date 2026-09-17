import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/groceries/model/grocery_item.dart';
import 'package:nestprep/features/groceries/model/grocery_suggestion.dart';
import 'package:nestprep/shared/text/normalised_name.dart';

GroceryItem bought(String name, {int minutesAgo = 0}) => GroceryItem(
  id: '$name-$minutesAgo',
  name: name,
  addedBy: 'm-sam',
  boughtAt: DateTime.utc(
    2026,
    9,
    17,
    12,
  ).subtract(Duration(minutes: minutesAgo)),
);

void main() {
  group('normalising a name', () {
    test('treats case and stray whitespace as the same thing', () {
      expect(normalisedName('Milk'), normalisedName('  milk '));
      expect(normalisedName('full  cream   milk'), 'full cream milk');
    });

    test('does not change what the person actually typed', () {
      const typed = '  Full Cream Milk ';
      expect(normalisedName(typed), 'full cream milk');
      expect(typed, '  Full Cream Milk ');
    });
  });

  group('ranking the chips', () {
    test('puts what the household buys most often first', () {
      final suggestions = rankSuggestions([
        bought('Milk', minutesAgo: 1),
        bought('Eggs', minutesAgo: 2),
        bought('Milk', minutesAgo: 3),
        bought('Milk', minutesAgo: 4),
      ]);
      expect(suggestions.map((s) => s.name), ['Milk', 'Eggs']);
      expect(suggestions.first.timesBought, 3);
    });

    test('counts spellings that differ only in case or spacing as one', () {
      final suggestions = rankSuggestions([
        bought('milk', minutesAgo: 1),
        bought('  MILK', minutesAgo: 2),
        bought('Milk ', minutesAgo: 3),
      ]);
      expect(suggestions, hasLength(1));
      expect(suggestions.single.timesBought, 3);
    });

    test('shows the most recent spelling, so a correction sticks', () {
      final suggestions = rankSuggestions([
        bought('Milk', minutesAgo: 1),
        bought('milk', minutesAgo: 9),
      ]);
      expect(suggestions.single.name, 'Milk');
      expect(suggestions.single.timesBought, 2);
    });

    test('a differently worded name is a different suggestion', () {
      final suggestions = rankSuggestions([
        bought('Full cream milk', minutesAgo: 1),
        bought('Milk', minutesAgo: 9),
      ]);
      expect(suggestions.map((s) => s.name), ['Full cream milk', 'Milk']);
    });

    test('breaks a tie by what was bought most recently', () {
      final suggestions = rankSuggestions([
        bought('Bread', minutesAgo: 1),
        bought('Eggs', minutesAgo: 2),
      ]);
      expect(suggestions.map((s) => s.name), ['Bread', 'Eggs']);
    });

    test('ignores an item whose name is only whitespace', () {
      expect(rankSuggestions([bought('   ')]), isEmpty);
    });

    test('shows at most the limit', () {
      final items = [
        for (var index = 0; index < 20; index++)
          bought('Item $index', minutesAgo: index),
      ];
      expect(rankSuggestions(items), hasLength(8));
      expect(rankSuggestions(items, limit: 3), hasLength(3));
    });

    test('has nothing to suggest before anything has been bought', () {
      expect(rankSuggestions([]), isEmpty);
    });
  });
}
