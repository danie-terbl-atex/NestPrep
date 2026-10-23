import '../../../shared/failure/app_failure.dart';
import '../../../shared/log/app_log.dart';
import '../../add_to_checkers/model/retailer_product.dart';
import '../model/pnp_contents.dart';
import 'pnp_catalogue_parser.dart';
import 'pnp_occ_client.dart';

/// What is in each product, from its Pick n Pay detail — search carries no
/// allergens or ingredients (add-to-pnp ADR-0002 §4). Details are national,
/// so each is remembered by code for the run, and read at most
/// [concurrency] at a time. A detail that cannot be read leaves that
/// product's contents unknown, which the lunch checks already treat safely:
/// never offered to a child with any allergy (lunch-box ADR-0012 §2).
final class PnpContentsReader {
  PnpContentsReader(this._occ);

  static const concurrency = 4;

  final PnpOccClient _occ;
  final _contents = <String, PnpContents>{};

  /// [products] with what their details say, in the same order.
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
    final contents = _contents[product.id] ?? await _read(product);
    return contents == null ? product : _with(product, contents);
  }

  /// The detail's contents, remembered — or null when it cannot be read,
  /// so the product stays unknown and the next search asks again.
  Future<PnpContents?> _read(RetailerProduct product) async {
    try {
      final contents = PnpCatalogueParser.contents(
        await _occ.get('/products/${product.id}', {
          'storeCode': product.storeId,
          'fields': 'code,classifications',
        }),
      );
      return _contents[product.id] = contents;
    } on PnpFailure catch (failure) {
      AppLog.failure('pnp product detail', code: failure.problem.name);
      return null;
    }
  }

  static RetailerProduct _with(RetailerProduct product, PnpContents contents) =>
      RetailerProduct(
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
