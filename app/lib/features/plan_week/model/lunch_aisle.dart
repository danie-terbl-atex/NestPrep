import '../../../shared/copy/lunch_aisle_copy.dart';
import '../../add_to_checkers/model/retailer_shelf.dart';
import '../../groceries/model/product_match.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'aisle_shelf.dart';

/// The shelves *Plan my week* reads before the model drafts anything, per
/// shop: Checkers' own Kids Lunchbox carousels, each with the compartment it
/// fills and a display category to fall back to (lunch-box ADR-0013), Pick n
/// Pay's own lunch box, snack, fruit and vegetable categories (lunch-box
/// ADR-0026), and Woolworths' browse groups.
abstract final class LunchAisle {
  /// At most this many shelves are read — and sent to the model.
  static const shelfLimit = 12;

  /// The shelf list as of 2026-10-01, read from the public
  /// `checkers.co.za/merchandised-page/kids-lunchbox-673eceeecfc3b2c11af1d5e4`.
  /// Drinks, lunch-box containers, bread, spreads and sandwich fillers are
  /// left out: there is no drink compartment, and the rest are not packed as
  /// they are. The page has no vegetables, so baby veg is a category.
  /// `appConfig/lunchAisle` replaces it without a release.
  static const checkersKidsLunchbox = [
    AisleShelf(
      title: LunchAisleCopy.shelfTummyFillers,
      slot: LunchSlot.main,
      list: RetailerShelf.productList('65f14802f9f1b74dd1317d2a'),
      category: RetailerShelf.displayCategory('67075db5ff98781136400735'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfCrunchTheColours,
      slot: LunchSlot.fruit,
      list: RetailerShelf.productList('675aa7a641a0d45728ad4134'),
      category: RetailerShelf.displayCategory('67075da7ff98781136400717'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfBabyVeg,
      slot: LunchSlot.veg,
      category: RetailerShelf.displayCategory('67075daeff98781136400728'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfYoghurtSnackTime,
      slot: LunchSlot.snack,
      list: RetailerShelf.productList('69d4ebed9cccb04862bcb67f'),
      category: RetailerShelf.displayCategory('67075e37ff987811364007b9'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfUnwrapASmile,
      slot: LunchSlot.snack,
      list: RetailerShelf.productList('695e3f976daf1b154d0dbc3c'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfJunkFreeFillers,
      slot: LunchSlot.snack,
      list: RetailerShelf.productList('695e37255b5748a09a5921d3'),
      category: RetailerShelf.displayCategory('6aabfd18c2519a563480913d'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfMindfulSnacking,
      slot: LunchSlot.snack,
      list: RetailerShelf.productList('69ddef09cbe29083fb9ad7f9'),
      category: RetailerShelf.displayCategory('6aabff83c2519a5634809bce'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfSqueezeSnackGo,
      slot: LunchSlot.snack,
      list: RetailerShelf.productList('69d4e44b2b56c452e2346b3b'),
      category: RetailerShelf.displayCategory('6aabeaa8c2519a5634801617'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfFreshlyBaked,
      slot: LunchSlot.snack,
      list: RetailerShelf.productList('65cfc0225cc51373c2ab397f'),
      category: RetailerShelf.displayCategory('670437e27a8738098af92e29'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfProteinFillers,
      slot: LunchSlot.snack,
      list: RetailerShelf.productList('675aafb7462a8112c964b4be'),
      category: RetailerShelf.displayCategory('6707a577c927aad4bab8dbe3'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfDriedFruitAndNuts,
      slot: LunchSlot.snack,
      list: RetailerShelf.productList('64b63d702eca23255007b6c1'),
      category: RetailerShelf.displayCategory('6aac0573c2519a563480b414'),
    ),
    AisleShelf(
      title: LunchAisleCopy.shelfCookiesAndBiscuits,
      slot: LunchSlot.treat,
      list: RetailerShelf.productList('65bb4f576a79cdbcd449b7b7'),
      category: RetailerShelf.displayCategory('67075e23ff987811364007a6'),
    ),
  ];

  /// Pick n Pay's categories as of 2026-10-12 (the vault's PnP reference):
  /// lunch box snacks and the snack aisle's children, yoghurt, fresh fruit
  /// and vegetables, and biscuits and chips for treats. No main shelf — the
  /// model drafts mains — and no chocolates or sweets, on purpose.
  /// `appConfig/lunchAisle.pnpShelves` replaces it without a release.
  static const pnpLunchBox = [
    AisleShelf(
      title: LunchAisleCopy.pnpLunchBoxSnacks,
      slot: LunchSlot.snack,
      category: RetailerShelf.pnpCategory('lunch-box-snacks-1664414929'),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpFreshFruit,
      slot: LunchSlot.fruit,
      category: RetailerShelf.pnpCategory('fresh-fruit789570456'),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpFreshVegetables,
      slot: LunchSlot.veg,
      category: RetailerShelf.pnpCategory('fresh-vegetables789570456'),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpYoghurt,
      slot: LunchSlot.snack,
      category: RetailerShelf.pnpCategory('yoghurt44805192'),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpHealthySnacks,
      slot: LunchSlot.snack,
      category: RetailerShelf.pnpCategory('healthy-snacks-1664414929'),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpBiltong,
      slot: LunchSlot.snack,
      category: RetailerShelf.pnpCategory('biltong-and-droewors-1664414929'),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpDriedFruitNutsSeeds,
      slot: LunchSlot.snack,
      category: RetailerShelf.pnpCategory(
        'dried-fruit-nuts-and-seeds-1664414929',
      ),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpBars,
      slot: LunchSlot.snack,
      category: RetailerShelf.pnpCategory(
        'cereal-protein-and-energy-bars-1664414929',
      ),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpPopcornPretzels,
      slot: LunchSlot.snack,
      category: RetailerShelf.pnpCategory(
        'popcorn-pretzels-and-crackers-1664414929',
      ),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpBiscuits,
      slot: LunchSlot.treat,
      category: RetailerShelf.pnpCategory('biscuits-and-crackers-1664414929'),
    ),
    AisleShelf(
      title: LunchAisleCopy.pnpChips,
      slot: LunchSlot.treat,
      category: RetailerShelf.pnpCategory('chips-and-dip-1664414929'),
    ),
  ];

  /// Woolworths' browse groups as of 2026-11-05, each read live at a store:
  /// sandwich fillers and bread for mains, the kids' fruit, the snacking
  /// vegetables, the lunchbox yoghurt, cheese, crackers and dried fruit, and
  /// biscuits and crisps for treats. Its fresh produce carries no contents.
  /// `appConfig/lunchAisle.woolworthsShelves` replaces it without a release.
  static const woolworthsLunchBox = [
    AisleShelf(
      title: LunchAisleCopy.woolworthsSandwichFillers,
      slot: LunchSlot.main,
      category: RetailerShelf.woolworthsGroup('cat782853'),
    ),
    AisleShelf(
      title: LunchAisleCopy.woolworthsBreadAndRolls,
      slot: LunchSlot.main,
      category: RetailerShelf.woolworthsGroup('cat735414'),
    ),
    AisleShelf(
      title: LunchAisleCopy.woolworthsFruitForLittleHands,
      slot: LunchSlot.fruit,
      category: RetailerShelf.woolworthsGroup('cat870106'),
    ),
    AisleShelf(
      title: LunchAisleCopy.woolworthsCrunchyVegSticks,
      slot: LunchSlot.veg,
      category: RetailerShelf.woolworthsGroup('cat869839', within: 'cat848672'),
    ),
    AisleShelf(
      title: LunchAisleCopy.woolworthsYoghurtTime,
      slot: LunchSlot.snack,
      category: RetailerShelf.woolworthsGroup('cat848682'),
    ),
    AisleShelf(
      title: LunchAisleCopy.woolworthsCheesePlease,
      slot: LunchSlot.snack,
      category: RetailerShelf.woolworthsGroup('cat848673'),
    ),
    AisleShelf(
      title: LunchAisleCopy.woolworthsCrackersAndRiceCakes,
      slot: LunchSlot.snack,
      category: RetailerShelf.woolworthsGroup('cat848679'),
    ),
    AisleShelf(
      title: LunchAisleCopy.woolworthsDriedFruitNibbles,
      slot: LunchSlot.snack,
      category: RetailerShelf.woolworthsGroup('ncat0010351'),
    ),
    AisleShelf(
      title: LunchAisleCopy.woolworthsBiscuitTin,
      slot: LunchSlot.treat,
      category: RetailerShelf.woolworthsGroup('cat845128'),
    ),
    AisleShelf(
      title: LunchAisleCopy.woolworthsCrispsAndCrunch,
      slot: LunchSlot.treat,
      category: RetailerShelf.woolworthsGroup('cat848678'),
    ),
  ];

  /// [shop]'s shelves when nothing replaces them.
  static List<AisleShelf> defaultsFor(ProductRetailer shop) => switch (shop) {
    ProductRetailer.checkers => checkersKidsLunchbox,
    ProductRetailer.pickNPay => pnpLunchBox,
    ProductRetailer.woolworths => woolworthsLunchBox,
  };

  /// The best sellers one shelf brings home at [shop]. Woolworths reads each
  /// new product's contents one call at a time, so its shelves bring fewer.
  static int productsPerShelf(ProductRetailer shop) => switch (shop) {
    ProductRetailer.checkers || ProductRetailer.pickNPay => 24,
    ProductRetailer.woolworths => 12,
  };

  /// `appConfig/lunchAisle`'s fields as [shop]'s shelves — `shelves` for
  /// Checkers, `pnpShelves` for Pick n Pay, `woolworthsShelves` for
  /// Woolworths: the ones this build can read, at most [shelfLimit]. Null
  /// when the document holds none for that shop, so the caller keeps
  /// [defaultsFor].
  static List<AisleShelf>? fromFields(
    Map<String, Object?> fields, {
    required ProductRetailer shop,
  }) {
    final (field, parse) = switch (shop) {
      ProductRetailer.checkers => ('shelves', AisleShelf.fromFields),
      ProductRetailer.pickNPay => ('pnpShelves', AisleShelf.fromPnpFields),
      ProductRetailer.woolworths => (
        'woolworthsShelves',
        AisleShelf.fromWoolworthsFields,
      ),
    };
    final shelves = switch (fields[field]) {
      final List<Object?> entries => [
        for (final entry in entries) ?parse(entry),
      ],
      _ => const <AisleShelf>[],
    };
    return shelves.isEmpty ? null : shelves.take(shelfLimit).toList();
  }
}
