import '../../add_to_checkers/data/retailer_catalogue.dart';
import '../../add_to_checkers/data/retailer_catalogues.dart';
import '../../groceries/model/product_match.dart';
import 'lunch_shop_choice.dart';

/// Which shop *Plan my week* plans at (lunch-box ADR-0026): the brief's
/// choice — shared with the lunch board's row — while it is still the
/// brief, and from the moment the ideas are drafted the shop that run began
/// at, so every shelf, search, price and match in one run is one shop's.
final class PlanWeekRetailer {
  PlanWeekRetailer({
    required this._catalogues,
    required this._choice,
    required this._isPnpOn,
  });

  final RetailerCatalogues _catalogues;
  final LunchShopChoice _choice;
  final bool Function() _isPnpOn;
  ProductRetailer? _running;

  /// The shop: the run's once it has begun, else the brief's choice.
  ProductRetailer get shop => _running ?? chosen;

  /// The brief's choice as it may be used now — Checkers while Pick n Pay is
  /// switched off.
  ProductRetailer get chosen => _choice.shopFor(isPnpOn: _isPnpOn());

  /// Whether the brief offers a choice at all (only with `addToPnp` on).
  bool get canChoose => _isPnpOn();

  /// The shops the brief offers, in their order.
  List<ProductRetailer> get choices => [
    for (final shop in ProductRetailer.values)
      if (shop.isConnected && (shop != ProductRetailer.pickNPay || canChoose))
        shop,
  ];

  /// The catalogue of [shop].
  RetailerCatalogue get catalogue => _catalogues.of(shop);

  void choose(ProductRetailer shop) => _choice.choose(shop);

  /// A run begins at the brief's choice and keeps it.
  void begin() => _running = chosen;

  /// Back at the brief: the next run takes the choice again.
  void end() => _running = null;
}
