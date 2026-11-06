import '../../../app/checkers_link_route.dart';
import '../../../app/pnp_link_route.dart';
import '../../../app/woolworths_link_route.dart';
import '../../groceries/model/product_match.dart';
import 'cart_push_flow.dart';

/// Where the member manages and makes [shop]'s link, for a cart push to send
/// them.
CartLinkPaths cartLinkPathsFor(ProductRetailer shop, String householdId) =>
    switch (shop) {
      ProductRetailer.checkers => (
        manage: CheckersLinkRoute.pathFor(householdId),
        returnWhenLinked: CheckersLinkRoute.pathFor(
          householdId,
          returnWhenLinked: true,
        ),
      ),
      ProductRetailer.pickNPay => (
        manage: PnpLinkRoute.pathFor(householdId),
        returnWhenLinked: PnpLinkRoute.pathFor(
          householdId,
          returnWhenLinked: true,
        ),
      ),
      ProductRetailer.woolworths => (
        manage: WoolworthsLinkRoute.pathFor(householdId),
        returnWhenLinked: WoolworthsLinkRoute.pathFor(
          householdId,
          returnWhenLinked: true,
        ),
      ),
    };

/// Whether [shop]'s push is sent each item's packs.
bool takesPackQuantities(ProductRetailer shop) => switch (shop) {
  ProductRetailer.checkers ||
  ProductRetailer.pickNPay ||
  ProductRetailer.woolworths => true,
};
