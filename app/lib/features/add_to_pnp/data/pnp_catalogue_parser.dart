import '../../../shared/failure/app_failure.dart';
import '../../../shared/money/money.dart';
import '../../add_to_checkers/model/pack_count.dart';
import '../../add_to_checkers/model/retailer_image_url.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../groceries/model/product_match.dart';
import '../model/pnp_contents.dart';

/// Reads Pick n Pay's commerce answers into typed values at the edge
/// (`ENG-09`) — the shapes in the vault's PnP API reference. A product that
/// does not read is left out; an answer that is not the shape at all is
/// `catalogueChanged`.
abstract final class PnpCatalogueParser {
  static final _code = RegExp(r'^([0-9]{6,20})_([A-Z]{2,3})$');

  /// Weighed by the gram (`_KGM`): its cart line needs a weight.
  static const _weighedUnit = 'KGM';

  /// The image formats in order of preference: the 300 px one fits a row.
  static const _imageFormats = ['carousel', 'product', 'listing'];

  /// A search or category page's products, as [storeCode] sells them.
  static List<RetailerProduct> products(Object? json, String storeCode) {
    if (json case {'products': final List<Object?> products}) {
      return [for (final product in products) ?_product(product, storeCode)];
    }
    throw const PnpFailure(PnpProblem.catalogueChanged);
  }

  /// The store a cart is priced at — its `baseStore.uid`.
  static String? storeCode(Object? cart) => switch (cart) {
    {'baseStore': {'uid': final String uid}} when uid.isNotEmpty => uid,
    _ => null,
  };

  /// An anonymous cart's id in URLs — its `guid`.
  static String? cartGuid(Object? cart) => switch (cart) {
    {'guid': final String guid} when guid.isNotEmpty => guid,
    _ => null,
  };

  /// The allergens, warnings and ingredients a product detail carries.
  static PnpContents contents(Object? detail) {
    final classes = switch (detail) {
      {'classifications': final List<Object?> classes} => classes,
      _ => const <Object?>[],
    };
    final allergens = [
      ..._values(classes, 'Silo/allergens'),
      ..._values(classes, 'Silo/allergens_warnings'),
    ];
    final ingredients = _values(classes, 'Silo/ingredients');
    return (
      allergenText: allergens.isEmpty ? null : '${allergens.join('. ')}.',
      ingredientsText: ingredients.isEmpty ? null : ingredients.join(' '),
    );
  }

  static RetailerProduct? _product(Object? json, String storeCode) {
    if (json case {
      'code': final String code,
      'name': final String rawName,
      'price': {'value': final num value},
    }) {
      final parts = _code.firstMatch(code);
      final name = rawName.trim();
      if (parts == null || name.isEmpty) return null;
      final unit = parts.group(2)!;
      final quantityType = json['quantityType'];
      final isSoldByWeight =
          unit == _weighedUnit ||
          (quantityType != null && quantityType != 'NORMAL');
      final price = _cents(value, isSoldByWeight: isSoldByWeight);
      if (price == null) return null;
      final oldPrice = switch (json['price']) {
        {'oldPrice': final num old} => _cents(old, isSoldByWeight: true),
        _ => null,
      };
      final hasDeal = switch (json['potentialPromotions']) {
        final List<Object?> promotions => promotions.isNotEmpty,
        _ => false,
      };
      final isOldHigher = oldPrice != null && oldPrice > price;
      return RetailerProduct(
        retailer: ProductRetailer.pickNPay,
        id: code,
        storeId: storeCode,
        articleCode: parts.group(1)!,
        unitOfMeasure: unit,
        name: name,
        price: Money(price),
        oldPrice: isOldHigher ? Money(oldPrice) : null,
        isOnPromotion: hasDeal || isOldHigher,
        isInStock: _isInStock(json),
        isSoldByWeight: isSoldByWeight,
        imageId: _imagePath(json['images']),
        packCount: packCountIn([name]),
      );
    }
    return null;
  }

  /// Cents from PnP's rand. Exact to the cent or nothing (`ENG-20`) — but a
  /// weighed product's price is per kilogram times an average and only ever
  /// shown, so it is rounded.
  static int? _cents(num rand, {required bool isSoldByWeight}) {
    if (rand < 0) return null;
    final cents = rand * 100;
    final whole = cents.round();
    if (isSoldByWeight || (cents - whole).abs() < 0.0001) return whole;
    return null;
  }

  static bool _isInStock(Map<Object?, Object?> json) => switch (json['stock']) {
    {'stockLevelStatus': final String status} => status != 'outOfStock',
    _ => json['inStockIndicator'] != false,
  };

  /// The image's path on PnP's CDN, without the leading `/` — the host is
  /// joined back by `retailerImageUrl`, so nothing stored can point elsewhere.
  static String? _imagePath(Object? images) {
    if (images is! List<Object?>) return null;
    final byFormat = <String, String>{};
    for (final image in images) {
      if (image case {'format': final String format, 'url': final String url}) {
        final uri = Uri.tryParse(url);
        if (uri == null || uri.host != pnpImageHost || uri.path.length < 2) {
          continue;
        }
        byFormat.putIfAbsent(format, () => uri.path.substring(1));
      }
    }
    for (final format in _imageFormats) {
      if (byFormat[format] case final path?) return path;
    }
    return byFormat.values.firstOrNull;
  }

  static List<String> _values(List<Object?> classes, String classCode) => [
    for (final entry in classes)
      if (entry
          case {
            'code': final String code,
            'features': final List<Object?> features,
          }
          when code == classCode)
        for (final feature in features)
          if (feature case {'featureValues': final List<Object?> values})
            for (final value in values)
              if (value case {'value': final String text}
                  when text.trim().isNotEmpty)
                text.trim(),
  ];
}
