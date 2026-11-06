import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/copy/shops_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../add_to_checkers/state/retailer_choice_controller.dart';
import '../../add_to_checkers/ui/retailer_logo.dart';
import '../../add_to_checkers/ui/shop_cart_links.dart';
import '../../groceries/model/product_match.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../model/shop_link.dart';
import '../state/shops_controller.dart';

/// *Your shops*: the shop the grocery list looks at first, and whether the
/// member's own account is linked at each shop switched on, with the way to
/// link or manage it.
class ShopsScreen extends StatelessWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final household = context.watch<HouseholdView>();
    final canShop = household.permissions.canEdit(HouseholdArea.groceries);
    final shops = context.watch<ShopsController>().shops;
    return NestScaffold(
      title: ShopsCopy.title,
      subtitle: ShopsCopy.subtitle(household.household.name),
      leading: backLeading(context),
      body: switch ((canShop, shops.isEmpty)) {
        (false, _) => const NestEmptyView(
          icon: LucideIcons.shoppingBasket,
          title: ShopsCopy.notYoursTitle,
          message: ShopsCopy.notYoursBody,
        ),
        (true, true) => const NestEmptyView(
          icon: LucideIcons.shoppingBasket,
          title: ShopsCopy.noneOnTitle,
          message: ShopsCopy.noneOnBody,
        ),
        (true, false) => _ShopsList(
          householdId: household.household.id,
          shops: shops,
        ),
      },
    );
  }
}

class _ShopsList extends StatelessWidget {
  const _ShopsList({required this.householdId, required this.shops});

  final String householdId;
  final List<ProductRetailer> shops;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final choice = context.watch<RetailerChoiceController>();
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        const NestSectionHeader(title: ShopsCopy.firstSection),
        const SizedBox(height: NestSpace.xs),
        Text(ShopsCopy.firstBody, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.sm),
        NestRiseIn(
          child: NestCard(
            padding: const EdgeInsets.all(NestSpace.xs),
            child: Column(
              children: [
                for (final shop in shops)
                  _FirstShopRow(
                    key: ValueKey('shops-first-${shop.code}'),
                    shop: shop,
                    isChosen: shop == choice.chosen,
                    onTap: () => choice.choose(shop),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: NestSpace.xl),
        const NestSectionHeader(title: ShopsCopy.accountsSection),
        const SizedBox(height: NestSpace.xs),
        Text(ShopsCopy.linkingNote, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.xs),
        Text(ShopsCopy.signInNote, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.sm),
        NestRiseIn(
          index: 1,
          child: NestCard(
            padding: const EdgeInsets.all(NestSpace.xs),
            child: Column(
              children: [
                for (final shop in shops)
                  _ShopLinkRow(
                    key: ValueKey('shops-link-${shop.code}'),
                    shop: shop,
                    householdId: householdId,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FirstShopRow extends StatelessWidget {
  const _FirstShopRow({
    required this.shop,
    required this.isChosen,
    required this.onTap,
    super.key,
  });

  final ProductRetailer shop;
  final bool isChosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: isChosen,
    inMutuallyExclusiveGroup: true,
    child: NestListRow(
      leading: RetailerLogo.decorative(retailer: shop),
      title: CheckersCopy.retailerName(shop),
      isSelected: isChosen,
      trailing: isChosen ? const Icon(LucideIcons.check) : null,
      onTap: onTap,
    ),
  );
}

class _ShopLinkRow extends StatelessWidget {
  const _ShopLinkRow({
    required this.shop,
    required this.householdId,
    super.key,
  });

  final ProductRetailer shop;
  final String householdId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ShopsController>();
    final (subtitle, action) = switch (controller.linkAt(shop)) {
      AsyncLoading() => (ShopsCopy.checking, null),
      AsyncFailure(:final failure) => (
        AppCopy.failure(failure),
        _ShopAction(
          shop: shop,
          label: AppCopy.retry,
          onPressed: () => unawaited(controller.refresh(shop)),
        ),
      ),
      AsyncData(value: ShopLink(isLinked: false)) => (
        ShopsCopy.notLinked,
        _ShopAction(
          shop: shop,
          label: ShopsCopy.link,
          onPressed: () => unawaited(_openLink(context, controller)),
        ),
      ),
      AsyncData(value: ShopLink(:final account)) => (
        account == null ? ShopsCopy.linked : ShopsCopy.linkedTo(account),
        _ShopAction(
          shop: shop,
          label: ShopsCopy.manage,
          onPressed: () => unawaited(_openLink(context, controller)),
        ),
      ),
    };
    return NestListRow(
      leading: RetailerLogo.decorative(retailer: shop),
      title: CheckersCopy.retailerName(shop),
      subtitle: subtitle,
      footer: action == null
          ? null
          : Align(alignment: AlignmentDirectional.centerStart, child: action),
    );
  }

  Future<void> _openLink(
    BuildContext context,
    ShopsController controller,
  ) async {
    await context.push<void>(cartLinkPathsFor(shop, householdId).manage);
    await controller.refresh(shop);
  }
}

class _ShopAction extends StatelessWidget {
  const _ShopAction({
    required this.shop,
    required this.label,
    required this.onPressed,
  });

  final ProductRetailer shop;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => NestButton(
    key: ValueKey('shops-action-${shop.code}'),
    label: label,
    variant: NestButtonVariant.tonal,
    size: NestButtonSize.small,
    isExpanded: false,
    onPressed: onPressed,
  );
}
