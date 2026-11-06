import '../../add_to_woolworths/data/woolworths_catalogue_parser.dart';
import '../../groceries/model/product_match.dart';

/// Where a shop's product picture is served, public and unauthenticated like
/// the catalogue. Checkers stores an image id; Pick n Pay a path on its own
/// CDN; Woolworths a file name and its query on its own — each joined to its
/// host here so a stored value can point nowhere else (groceries ADR-0007).
Uri? retailerImageUrl(ProductRetailer retailer, String imageId) =>
    switch (retailer) {
      ProductRetailer.checkers => Uri.https(
        'catalog.sixty60.co.za',
        '/v2/files/$imageId',
        const {'width': '300', 'height': '300'},
      ),
      ProductRetailer.pickNPay => Uri.https(pnpImageHost, '/$imageId'),
      ProductRetailer.woolworths => _woolworthsImageUrl(imageId),
    };

/// Pick n Pay's image CDN.
const pnpImageHost = 'cdn-prd-02.pnp.co.za';

Uri? _woolworthsImageUrl(String imageId) {
  if (!WoolworthsCatalogueParser.isImageId(imageId)) return null;
  final separator = imageId.endsWith('&') || imageId.endsWith('?')
      ? ''
      : imageId.contains('?')
      ? '&'
      : '?';
  final url = Uri.tryParse(
    'https://${WoolworthsCatalogueParser.imageHost}/'
    '$imageId${separator}w=200&q=85',
  );
  return url == null ||
          url.host != WoolworthsCatalogueParser.imageHost ||
          url.hasFragment
      ? null
      : url;
}
