import '../../../shared/failure/app_failure.dart';
import '../../../shared/money/money.dart';
import '../model/checkers_product.dart';
import '../model/checkers_store.dart';

/// Turns the catalogue's decoded JSON into typed stores and products — the
/// one place the raw shape exists (`ENG-09`).
///
/// A whole answer of the wrong shape is [CheckersProblem.catalogueChanged]; a
/// single product missing something it needs is left out, so one odd entry
/// never costs a person the other four.
abstract final class CheckersCatalogueParser {
  static const _priceFactor = 100;

  /// The stores in a `store-contexts` answer that deliver within the hour.
  static List<CheckersStore> sixtyMinuteStores(Object? json) {
    final items = switch (json) {
      {'items': final List<Object?> items} => items,
      _ => throw const CheckersFailure(CheckersProblem.catalogueChanged),
    };
    return [
      for (final item in items)
        if (_store(item) case final store? when store.deliversInSixtyMinutes)
          store,
    ];
  }

  /// The products in a `products/filter` answer, in the order Checkers ranked
  /// them.
  static List<CheckersProduct> products(Object? json) {
    final products = switch (json) {
      {'products': final List<Object?> products} => products,
      _ => throw const CheckersFailure(CheckersProblem.catalogueChanged),
    };
    return [for (final entry in products) ?_product(entry)];
  }

  static CheckersStore? _store(Object? json) {
    if (json
        case {
          'storeId': final String storeId,
          'serviceOptionIds': final List<Object?> serviceOptionIds,
        }
        when storeId.isNotEmpty) {
      return CheckersStore(
        storeId: storeId,
        serviceOptionIds: serviceOptionIds.whereType<String>().toList(),
        hasCapacity: switch (json['hasCapacity']) {
          final List<Object?> capacity => capacity.whereType<String>().toList(),
          _ => const [],
        },
        brandPriority: switch (json['brandPriority']) {
          final int priority => priority,
          _ => null,
        },
      );
    }
    return null;
  }

  static CheckersProduct? _product(Object? json) {
    if (json
        case {
          'id': final String id,
          'storeId': final String storeId,
          'articleNumber': final String articleNumber,
          'unitOfMeasure': final String unitOfMeasure,
          'priceWithoutDecimal': final int rawPrice,
        }
        when id.isNotEmpty && unitOfMeasure.isNotEmpty) {
      final name = _nonEmpty(json['displayName']) ?? _nonEmpty(json['name']);
      final factor = switch (json['priceFactor']) {
        final int factor when factor > 0 => factor,
        _ => _priceFactor,
      };
      final price = _cents(rawPrice, factor);
      if (name == null || price == null) return null;
      final oldPrice = switch (json['oldPrice']) {
        final int old => _cents(old, factor),
        _ => null,
      };
      return CheckersProduct(
        id: id,
        storeId: storeId,
        articleNumber: articleNumber,
        unitOfMeasure: unitOfMeasure,
        name: name,
        brand: _nonEmpty(json['brand']),
        price: Money(price),
        // Checkers sends the current price as `oldPrice` when nothing is
        // reduced; only a higher one is a *was* price.
        oldPrice: oldPrice != null && oldPrice > price ? Money(oldPrice) : null,
        isOnPromotion: json['isOnPromotion'] == true,
        isInStock: json['isStockAvailable'] == true,
        imageId: _nonEmpty(json['imageId']),
        allergenText: _attribute(json['attributes'], 'Allergens'),
        ingredientsText: _attribute(json['attributes'], 'Ingredients'),
        packCount: _packCount(json, name),
      );
    }
    return null;
  }

  /// Cents from a value scaled by [factor] — only when it is exact, because
  /// money is never rounded on the way in (`ENG-20`).
  static int? _cents(int value, int factor) {
    if (factor == _priceFactor) return value;
    final scaled = value * _priceFactor;
    return scaled % factor == 0 ? scaled ~/ factor : null;
  }

  /// One named entry of a product's `attributes`, as plain text: the shop
  /// writes some of them as HTML.
  static String? _attribute(Object? attributes, String name) {
    if (attributes is! List<Object?>) return null;
    for (final attribute in attributes) {
      if (attribute case {'name': final String key, 'value': final String value}
          when key == name) {
        return _nonEmpty(_plainText(value));
      }
    }
    return null;
  }

  static String _plainText(String html) => html
      .replaceAll(RegExp('<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static final _timesPattern = RegExp(
    r'(\d{1,3})\s*[x×]\s*\d',
    caseSensitive: false,
  );
  static final _packPattern = RegExp(
    r'(\d{1,3})\s*(?:-\s*)?(?:pack|pk|\x27s)\b',
    caseSensitive: false,
  );

  /// How many units a pack holds, when the shop says so plainly: a pack
  /// quantity above one, or "6 x 100g" / "6 pack" / "6's" in the name or
  /// the box contents. Never guessed past that.
  static int? _packCount(Map<Object?, Object?> json, String name) {
    if (json['packQuantity'] case final int quantity when quantity > 1) {
      return quantity;
    }
    final contents = switch (json['boxContent']) {
      final String text => _plainText(text),
      _ => '',
    };
    for (final text in [name, contents]) {
      final match =
          _timesPattern.firstMatch(text) ?? _packPattern.firstMatch(text);
      final count = int.tryParse(match?.group(1) ?? '');
      if (count != null && count > 1) return count;
    }
    return null;
  }

  static String? _nonEmpty(Object? value) => switch (value) {
    final String text when text.trim().isNotEmpty => text.trim(),
    _ => null,
  };
}
