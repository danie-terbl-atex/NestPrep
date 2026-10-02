import '../../../shared/copy/plan_week_copy.dart';
import '../../add_to_checkers/model/checkers_shelf.dart';
import '../../lunch_box/model/lunch_slot.dart';
import 'aisle_shelf.dart';

/// The shelves *Plan my week* reads before the model drafts anything
/// (lunch-box ADR-0013): Checkers' own Kids Lunchbox carousels, each with
/// the compartment it fills and a display category to fall back to.
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
      title: PlanWeekCopy.shelfTummyFillers,
      slot: LunchSlot.main,
      list: CheckersShelf.productList('65f14802f9f1b74dd1317d2a'),
      category: CheckersShelf.displayCategory('67075db5ff98781136400735'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfCrunchTheColours,
      slot: LunchSlot.fruit,
      list: CheckersShelf.productList('675aa7a641a0d45728ad4134'),
      category: CheckersShelf.displayCategory('67075da7ff98781136400717'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfBabyVeg,
      slot: LunchSlot.veg,
      category: CheckersShelf.displayCategory('67075daeff98781136400728'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfYoghurtSnackTime,
      slot: LunchSlot.snack,
      list: CheckersShelf.productList('69d4ebed9cccb04862bcb67f'),
      category: CheckersShelf.displayCategory('67075e37ff987811364007b9'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfUnwrapASmile,
      slot: LunchSlot.snack,
      list: CheckersShelf.productList('695e3f976daf1b154d0dbc3c'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfJunkFreeFillers,
      slot: LunchSlot.snack,
      list: CheckersShelf.productList('695e37255b5748a09a5921d3'),
      category: CheckersShelf.displayCategory('6aabfd18c2519a563480913d'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfMindfulSnacking,
      slot: LunchSlot.snack,
      list: CheckersShelf.productList('69ddef09cbe29083fb9ad7f9'),
      category: CheckersShelf.displayCategory('6aabff83c2519a5634809bce'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfSqueezeSnackGo,
      slot: LunchSlot.snack,
      list: CheckersShelf.productList('69d4e44b2b56c452e2346b3b'),
      category: CheckersShelf.displayCategory('6aabeaa8c2519a5634801617'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfFreshlyBaked,
      slot: LunchSlot.snack,
      list: CheckersShelf.productList('65cfc0225cc51373c2ab397f'),
      category: CheckersShelf.displayCategory('670437e27a8738098af92e29'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfProteinFillers,
      slot: LunchSlot.snack,
      list: CheckersShelf.productList('675aafb7462a8112c964b4be'),
      category: CheckersShelf.displayCategory('6707a577c927aad4bab8dbe3'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfDriedFruitAndNuts,
      slot: LunchSlot.snack,
      list: CheckersShelf.productList('64b63d702eca23255007b6c1'),
      category: CheckersShelf.displayCategory('6aac0573c2519a563480b414'),
    ),
    AisleShelf(
      title: PlanWeekCopy.shelfCookiesAndBiscuits,
      slot: LunchSlot.treat,
      list: CheckersShelf.productList('65bb4f576a79cdbcd449b7b7'),
      category: CheckersShelf.displayCategory('67075e23ff987811364007a6'),
    ),
  ];

  /// `appConfig/lunchAisle`'s fields as shelves: the ones this build can
  /// read, at most [shelfLimit]. Null when the document holds none, so the
  /// caller keeps [checkersKidsLunchbox].
  static List<AisleShelf>? fromFields(Map<String, Object?> fields) {
    final shelves = switch (fields['shelves']) {
      final List<Object?> entries => [
        for (final entry in entries) ?AisleShelf.fromFields(entry),
      ],
      _ => const <AisleShelf>[],
    };
    return shelves.isEmpty ? null : shelves.take(shelfLimit).toList();
  }
}
