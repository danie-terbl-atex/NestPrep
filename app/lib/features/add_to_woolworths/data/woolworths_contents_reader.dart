import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../model/woolworths_store.dart';
import 'woolworths_catalogue_parser.dart';
import 'woolworths_web_client.dart';

/// What is in each product, from its `getProductInfo` detail — Constructor
/// carries no allergens or ingredients. Details are national, so each is
/// remembered by SKU for the run, and read at most [concurrency] at a time.
/// A detail that cannot be read leaves that product's contents unknown,
/// which the lunch checks already treat safely (lunch-box ADR-0012 §2).
final class WoolworthsContentsReader {
  WoolworthsContentsReader(this._web);

  static const concurrency = 4;

  final WoolworthsWebClient _web;
  final _contents = <String, WoolworthsContents>{};

  Future<List<RetailerProduct>> withContents(
    List<RetailerProduct> products,
  ) async {
    final result = <RetailerProduct>[];
    for (var start = 0; start < products.length; start += concurrency) {
      final batch = products.skip(start).take(concurrency);
      result.addAll(await Future.wait(batch.map(_fill)));
    }
    return result;
  }

  Future<RetailerProduct> _fill(RetailerProduct product) async {
    final contents = _contents[product.id] ?? await _read(product.id);
    return contents == null ? product : _with(product, contents);
  }

  Future<WoolworthsContents?> _read(String sku) async {
    try {
      final contents = WoolworthsCatalogueParser.contents(
        await _web.site('getProductInfo', {'productURL': '/prod/_/A-$sku'}),
      );
      return _contents[sku] = contents;
    } on WoolworthsFailure catch (failure) {
      AppLog.failure('woolworths product detail', code: failure.problem.name);
      return null;
    }
  }

  static RetailerProduct _with(
    RetailerProduct product,
    WoolworthsContents contents,
  ) => RetailerProduct(
    retailer: product.retailer,
    id: product.id,
    storeId: product.storeId,
    articleCode: product.articleCode,
    unitOfMeasure: product.unitOfMeasure,
    name: product.name,
    brand: product.brand,
    price: product.price,
    oldPrice: product.oldPrice,
    isOnPromotion: product.isOnPromotion,
    isInStock: product.isInStock,
    isSoldByWeight: product.isSoldByWeight,
    imageId: product.imageId,
    allergenText: contents.allergenText,
    ingredientsText: contents.ingredientsText,
    packCount: product.packCount,
  );
}
