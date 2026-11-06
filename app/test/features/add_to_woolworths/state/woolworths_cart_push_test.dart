import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/add_to_checkers/model/cart_push_state.dart';
import 'package:nestprep/features/add_to_checkers/state/cart_push_controller.dart';
import 'package:nestprep/features/add_to_checkers/ui/shop_cart_links.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_woolworths.dart';
import '../../../support/household_fixtures.dart';

void main() {
  late FakeWoolworthsDirectory directory;
  late CartPushController push;

  setUp(() {
    directory = FakeWoolworthsDirectory();
    push = CartPushController(
      directory: directory,
      householdId: Fixtures.householdId,
    );
    addTearDown(push.dispose);
  });

  test('Woolworths is sent each item’s packs', () async {
    expect(takesPackQuantities(ProductRetailer.woolworths), isTrue);
    await push.push(['a', 'b'], quantities: const {'a': 2, 'b': 1});
    expect(directory.pushes.single.quantities, {'a': 2, 'b': 1});
    expect(push.state, isA<CartPushed>());
  });

  for (final problem in [
    WoolworthsProblem.notLinked,
    WoolworthsProblem.linkExpired,
  ]) {
    test(
      '${problem.name} sends the member to link, then pushes again',
      () async {
        directory.pushFailures.add(WoolworthsFailure(problem));
        await push.push(['a']);
        expect(push.state, isA<CartPushNeedsLink>());
        await push.retry();
        expect(directory.pushes, hasLength(2));
        expect(push.state, isA<CartPushed>());
      },
    );
  }

  test('a refused cart is a failure, not a link', () async {
    directory.pushFailures.add(
      const WoolworthsFailure(WoolworthsProblem.cartRefused),
    );
    await push.push(['a']);
    expect(push.state, isA<CartPushFailed>());
  });

  test('the link screen is the one for the shop', () {
    expect(cartLinkPathsFor(ProductRetailer.woolworths, 'h1'), (
      manage: '/households/h1/woolworths',
      returnWhenLinked: '/households/h1/woolworths?return=1',
    ));
  });
}
