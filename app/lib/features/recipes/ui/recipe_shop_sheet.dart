import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../add_to_checkers/data/checkers_area_preference.dart';
import '../../add_to_checkers/data/checkers_directory.dart';
import '../../add_to_checkers/data/checkers_place_resolver.dart';
import '../../add_to_checkers/data/product_match_ranker.dart';
import '../../add_to_checkers/data/retailer_catalogues.dart';
import '../../add_to_checkers/data/retailer_preference.dart';
import '../../add_to_checkers/state/cart_push_controller.dart';
import '../../add_to_checkers/state/shop_carts.dart';
import '../../add_to_checkers/ui/checkers_area_sheet.dart';
import '../../add_to_pnp/data/pnp_directory.dart';
import '../../groceries/data/grocery_repository.dart';
import '../../groceries/model/product_match.dart';
import '../../live_location/data/location_source.dart';
import '../../plan_week/data/shop_week_groceries.dart';
import '../../plan_week/ui/plan_week_shop_picker.dart';
import '../data/recipe_groceries.dart';
import '../model/recipe_shop_line.dart';
import '../state/recipe_shop_controller.dart';
import 'recipe_product_choice.dart';
import 'recipe_shop_footer.dart';
import 'recipe_shop_row.dart';

/// *Add to grocer* (recipes ADR-0005): [lines] — what a planned recipe still
/// needs — looked for at the shop the grocery list's *Shop at* last chose,
/// among [shops], in a sheet that lives as long as it is open. Everything it
/// needs is read from [context] first: a sheet is not under the page's
/// providers. Answers how many lines went on the list, or null when none did.
///
/// Snap a list opens it too, with a photo's lines (list-scan ADR-0001).
Future<int?> showRecipeShopSheet(
  BuildContext context, {
  required String householdId,
  required String memberId,
  required List<ProductRetailer> shops,
  required List<RecipeShopLine> lines,
}) async {
  final preference = context.read<RetailerPreference>();
  final groceryRepository = context.read<GroceryRepository>();
  final controller = RecipeShopController(
    catalogues: context.read<RetailerCatalogues>(),
    placeResolver: CheckersPlaceResolver(
      locationSource: context.read<LocationSource>(),
      areaPreference: context.read<CheckersAreaPreference>(),
    ),
    groceries: RecipeGroceries(
      groceryRepository: groceryRepository,
      matched: ShopWeekGroceries(
        groceryRepository: groceryRepository,
        householdId: householdId,
        memberId: memberId,
      ),
      householdId: householdId,
      memberId: memberId,
    ),
    householdId: householdId,
    ranker: context.read<ProductMatchRanker>(),
  );
  final carts = ShopCarts(
    checkers: CartPushController(
      directory: context.read<CheckersDirectory>(),
      householdId: householdId,
    ),
    pickNPay: CartPushController(
      directory: context.read<PnpDirectory>(),
      householdId: householdId,
    ),
  );
  final saved = await preference.read(householdId);
  unawaited(
    controller.start(
      shop: saved != null && shops.contains(saved) ? saved : shops.first,
      lines: lines,
    ),
  );
  if (!context.mounted) {
    controller.dispose();
    carts.dispose();
    return null;
  }
  await showNestSheet<void>(
    context: context,
    title: RecipeShopCopy.sheetTitle,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: controller),
        Provider.value(value: carts),
      ],
      child: RecipeShopView(
        householdId: householdId,
        shops: shops,
        onChooseShop: (shop) {
          unawaited(preference.write(householdId, shop));
          unawaited(controller.chooseShop(shop));
        },
      ),
    ),
  );
  final added = controller.addedCount;
  controller.dispose();
  carts.dispose();
  return added;
}

/// The sheet's body: the shop and where it looks, how far the search has
/// got, each line as found, then what to do with them.
class RecipeShopView extends StatelessWidget {
  const RecipeShopView({
    required this.householdId,
    required this.shops,
    required this.onChooseShop,
    super.key,
  });

  final String householdId;
  final List<ProductRetailer> shops;
  final ValueChanged<ProductRetailer> onChooseShop;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<RecipeShopController>();
    final shop = controller.shop;
    if (shop == null) return const NestSkeleton.rows();
    final lines = controller.lines;
    final isOnList = controller.listed != null;
    final place = controller.place;
    final settled = lines.where((line) => line.isSettled).length;
    // Everything but the actions scrolls, so at 200% text the lines are
    // still reachable and the actions stay in reach (`FE-14`).
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (shops.length > 1 && !isOnList) ...[
                PlanWeekShopPicker(
                  shops: shops,
                  chosen: shop,
                  onChoose: onChooseShop,
                ),
                const SizedBox(height: NestSpace.sm),
              ],
              Wrap(
                spacing: NestSpace.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(switch (place) {
                    null => CheckersCopy.matchesLoading(shop),
                    _ when place.isDevice => CheckersCopy.nearYou,
                    _ => CheckersCopy.nearArea(place.area!.label),
                  }, style: nest.text.caption),
                  if (!isOnList)
                    NestButton(
                      label: CheckersCopy.changeArea,
                      icon: LucideIcons.mapPin,
                      variant: NestButtonVariant.ghost,
                      size: NestButtonSize.small,
                      isExpanded: false,
                      onPressed: () => showCheckersAreaSheet(
                        context: context,
                        current: place?.area,
                        onChoose: controller.chooseArea,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: NestSpace.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  controller.isSettled
                      ? RecipeShopCopy.found(shop)
                      : RecipeShopCopy.searching(shop, settled, lines.length),
                  style: nest.text.bodySecondary,
                ),
              ),
              const SizedBox(height: NestSpace.sm),
              for (final line in lines)
                RecipeShopRow(
                  key: ValueKey('recipe-shop-${line.index}'),
                  line: line,
                  shop: shop,
                  onToggle: isOnList
                      ? null
                      : () => controller.toggle(line.index),
                  onChange: isOnList
                      ? null
                      : () => _change(context, controller, line),
                ),
            ],
          ),
        ),
        const SizedBox(height: NestSpace.md),
        RecipeShopFooter(householdId: householdId),
      ],
    );
  }

  static Future<void> _change(
    BuildContext context,
    RecipeShopController controller,
    RecipeShopLine line,
  ) async {
    final product = await showRecipeProductChoice(context: context, line: line);
    if (product != null) controller.choose(line.index, product);
  }
}
