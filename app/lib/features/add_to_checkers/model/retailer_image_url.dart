import '../../groceries/model/product_match.dart';

/// Where a shop's product picture is served, public and unauthenticated like
/// the catalogue. Checkers stores an image id; Pick n Pay a path on its own
/// CDN, joined to that host here so a stored value can point nowhere else
/// (groceries ADR-0007).
Uri? retailerImageUrl(ProductRetailer retailer, String imageId) =>
    switch (retailer) {
      ProductRetailer.checkers => Uri.https(
        'catalog.sixty60.co.za',
        '/v2/files/$imageId',
        const {'width': '300', 'height': '300'},
      ),
      ProductRetailer.pickNPay => Uri.https(pnpImageHost, '/$imageId'),
      ProductRetailer.woolworths => null,
    };

/// Pick n Pay's image CDN.
const pnpImageHost = 'cdn-prd-02.pnp.co.za';
