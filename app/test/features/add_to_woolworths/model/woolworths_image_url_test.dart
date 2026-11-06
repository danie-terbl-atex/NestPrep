import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/retailer_image_url.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';

void main() {
  Uri? url(String imageId) =>
      retailerImageUrl(ProductRetailer.woolworths, imageId);

  test('a stored image is on Woolworths’ host, sized for a row', () {
    expect(
      url('Milk-20011697.jpg?V=Q83t&o=eyJ9&').toString(),
      'https://assets.woolworthsstatic.co.za/Milk-20011697.jpg?V=Q83t&o=eyJ9&w=200&q=85',
    );
    expect(
      url('Milk-20011697.jpg?V=Q83t').toString(),
      'https://assets.woolworthsstatic.co.za/Milk-20011697.jpg?V=Q83t&w=200&q=85',
    );
    expect(
      url('Milk-20011697.jpg').toString(),
      'https://assets.woolworthsstatic.co.za/Milk-20011697.jpg?w=200&q=85',
    );
  });

  test('a stored value can point nowhere else', () {
    for (final imageId in [
      '/evil.com/x.jpg',
      '@evil.com',
      'x.jpg#frag',
      'a b.jpg',
      '',
    ]) {
      final found = url(imageId);
      expect(
        found == null || found.host == 'assets.woolworthsstatic.co.za',
        isTrue,
        reason: imageId,
      );
      expect(found?.hasFragment ?? false, isFalse, reason: imageId);
    }
  });
}
