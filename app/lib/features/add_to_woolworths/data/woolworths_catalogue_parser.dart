import '../../../shared/failure/app_failure.dart';
import '../../../shared/money/money.dart';
import '../../add_to_checkers/model/pack_count.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../../groceries/model/product_match.dart';
import '../model/woolworths_store.dart';

/// Reads Woolworths' answers — `validatePlace`, Constructor's search and
/// browse, `getProductInfo` — into typed values at the edge (`ENG-09`). A
/// product that does not read is left out; an answer that is not the shape
/// at all is `catalogueChanged`.
abstract final class WoolworthsCatalogueParser {
  static final _sku = RegExp(r'^[0-9]{6,14}$');
  static final _variableWeightSku = RegExp(r'^2[0-9]{12}$');
  static final _averageWeight = RegExp(r'\bavg\b', caseSensitive: false);
  static final _deliveryDetails = RegExp(r'^([0-9]+)-(plist[0-9]+)');

  static const imageHost = 'assets.woolworthsstatic.co.za';
  static const _imagePrefix = 'https://$imageHost/';
  static const imageIdLimit = 600;

  static const defaultPriceZone = 'p30';
  static const _priceZones = {
    'plist3620006': 'p10',
    'plist3620008': 'p30',
    'plist3620009': 'p60',
  };

  /// The store and price list `validatePlace` fulfils a point from.
  static WoolworthsStore store(Object? json) {
    if (json case {'deliveryDetails': final String details}) {
      if (json['deliverable'] == false) {
        throw const WoolworthsFailure(WoolworthsProblem.noStoreNearby);
      }
      final parts = _deliveryDetails.firstMatch(details);
      if (parts != null) {
        return WoolworthsStore(
          id: parts.group(1)!,
          priceZone: _priceZones[parts.group(2)] ?? defaultPriceZone,
        );
      }
      if (details.startsWith('-')) {
        throw const WoolworthsFailure(WoolworthsProblem.noStoreNearby);
      }
    }
    throw const WoolworthsFailure(WoolworthsProblem.catalogueChanged);
  }

  /// A search or browse page's products, as [store] sells them.
  static List<RetailerProduct> products(Object? json, WoolworthsStore store) {
    if (json case {'response': {'results': final List<Object?> results}}) {
      return [for (final result in results) ?_product(result, store)];
    }
    throw const WoolworthsFailure(WoolworthsProblem.catalogueChanged);
  }

  /// The ingredients and allergens a product detail carries.
  static WoolworthsContents contents(Object? detail) {
    final ingredients = switch (detail) {
      {'textualAttributes': {'INGREDIENTS': final String text}}
          when text.trim().isNotEmpty =>
        text.trim(),
      _ => null,
    };
    final allergens = [
      if (detail case {'multiAttributes': final List<Object?> attributes})
        for (final attribute in attributes)
          if (attribute case {'type': 'ALLERGENS', 'text': final String text}
              when text.trim().isNotEmpty)
            text.trim(),
    ];
    return (
      allergenText: allergens.isEmpty ? null : allergens.join(' '),
      ingredientsText: ingredients,
    );
  }

  /// Whether a product is weighed at the till: an average-weight pack, or a
  /// variable-weight barcode (13 digits starting `2`).
  static bool isSoldByWeight({required String sku, required String name}) =>
      _variableWeightSku.hasMatch(sku) || _averageWeight.hasMatch(name);

  /// The file name and query after Woolworths' image host — null when the
  /// URL is elsewhere, or the rest could not be stored safely.
  static String? imageId(Object? imageUrl) {
    if (imageUrl is! String || !imageUrl.startsWith(_imagePrefix)) return null;
    final id = imageUrl.substring(_imagePrefix.length);
    return isImageId(id) ? id : null;
  }

  static bool isImageId(String id) =>
      id.isNotEmpty &&
      id.length <= imageIdLimit &&
      !id.contains('/') &&
      !id.contains(RegExp(r'\s'));

  static RetailerProduct? _product(Object? json, WoolworthsStore store) {
    if (json case {'data': final Map<Object?, Object?> data}) {
      final sku = data['id'];
      final rawName = json['value'] ?? data['description'];
      if (sku is! String || !_sku.hasMatch(sku) || rawName is! String) {
        return null;
      }
      final name = rawName.trim();
      if (name.isEmpty) return null;
      final zone = store.priceZone;
      final weighed = isSoldByWeight(sku: sku, name: name);
      final price = _cents(
        weighed ? data['${zone}_kg'] ?? data[zone] : data[zone],
        isSoldByWeight: weighed,
      );
      if (price == null) return null;
      final wasPrice = _cents(data['${zone}_wp'], isSoldByWeight: weighed);
      final isWasHigher = wasPrice != null && wasPrice > price;
      final hasDeal = switch (data['promo']) {
        final List<Object?> promotions => promotions.isNotEmpty,
        _ => false,
      };
      return RetailerProduct(
        retailer: ProductRetailer.woolworths,
        id: sku,
        storeId: store.id,
        articleCode: sku,
        unitOfMeasure: weighed ? 'KG' : 'EA',
        name: name,
        brand: switch (data['brand']) {
          final String brand when brand.trim().isNotEmpty => brand.trim(),
          _ => null,
        },
        price: Money(price),
        oldPrice: isWasHigher ? Money(wasPrice) : null,
        isOnPromotion: hasDeal || isWasHigher,
        isInStock: true,
        isSoldByWeight: weighed,
        imageId: imageId(data['image_url']),
        packCount: packCountIn([name]),
      );
    }
    return null;
  }

  /// Cents from Woolworths' rand: exact to the cent or nothing (`ENG-20`),
  /// except a weighed product's, which is only ever shown.
  static int? _cents(Object? rand, {required bool isSoldByWeight}) {
    if (rand is! num || rand <= 0) return null;
    final cents = rand * 100;
    final whole = cents.round();
    if (isSoldByWeight || (cents - whole).abs() < 0.0001) return whole;
    return null;
  }
}
