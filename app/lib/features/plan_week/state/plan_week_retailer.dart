import '../../add_to_checkers/data/retailer_catalogue.dart';
import '../../add_to_checkers/data/retailer_catalogues.dart';
import '../../groceries/model/product_match.dart';
import 'lunch_shop_choice.dart';

/// Which shop *Plan my week* plans at (lunch-box ADR-0026): the brief's
/// choice among the shops switched on — shared with the lunch board's row —
/// while it is still the brief, and from the moment the ideas are drafted
/// the shop that run began at, so every shelf, search, price and match in
/// one run is one shop's.
final class PlanWeekRetailer {
  PlanWeekRetailer({
    required this._catalogues,
    required this._choice,
    required this._shopsOn,
  });

  final RetailerCatalogues _catalogues;
  final LunchShopChoice _choice;
  final List<ProductRetailer> Function() _shopsOn;
  ProductRetailer? _running;

  /// The shop: the run's once it has begun, else the brief's choice.
  ProductRetailer get shop => _running ?? chosen;

  /// The brief's choice as it may be used now: the chosen shop while it is
  /// switched on, else the first that is.
  ProductRetailer get chosen =>
      // Reached by link with every shop switched off: the first shop, as
      // before shops had switches here.
      _choice.shopFor(choices) ?? ProductRetailer.values.first;

  /// Whether the brief offers a choice at all.
  bool get canChoose => choices.length > 1;

  /// The shops the brief offers, in their order.
  List<ProductRetailer> get choices => _shopsOn();

  /// The catalogue of [shop].
  RetailerCatalogue get catalogue => _catalogues.of(shop);

  void choose(ProductRetailer shop) => _choice.choose(shop);

  /// A run begins at the brief's choice and keeps it.
  void begin() => _running = chosen;

  /// Back at the brief: the next run takes the choice again.
  void end() => _running = null;
}
