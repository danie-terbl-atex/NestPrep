import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../groceries/model/product_match.dart';
import '../state/retailer_choice_controller.dart';
import 'retailer_logo.dart';
import 'shops_on_list.dart';

/// The chosen shop's logo at the start of the grocery add field
/// (add-to-checkers ADR-0007): ringed while its products show as somebody
/// types, plain while they do not. Tapping it chooses the shop, or turns
/// matching as you type off — it is also where *Find at* and *Shop at* get
/// their shop.
class MatchAsYouTypeButton extends StatelessWidget {
  const MatchAsYouTypeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final choice = context.watch<RetailerChoiceController>();
    final shop = choice.chosen;
    final isOn = choice.matchesAsYouType;
    return RetailerLogo(
      retailer: shop,
      size: NestSize.logoMedium,
      tone: isOn ? NestLogoTileTone.selected : NestLogoTileTone.idle,
      label: isOn
          ? CheckersCopy.matchingAsYouType(shop)
          : CheckersCopy.notMatchingAsYouType,
      onTap: () =>
          _showSheet(context, choice, shopsOnList(context, listen: false)),
    );
  }

  Future<void> _showSheet(
    BuildContext context,
    RetailerChoiceController choice,
    List<ProductRetailer> available,
  ) => showNestSheet<void>(
    context: context,
    title: CheckersCopy.matchAsYouTypeTitle,
    builder: (sheetContext) {
      void close(VoidCallback then) {
        Navigator.of(sheetContext).pop();
        then();
      }

      final isOn = choice.matchesAsYouType;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CheckersCopy.matchAsYouTypeBody,
            style: NestTheme.of(sheetContext).text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.md),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final shop in ProductRetailer.values)
                  _ShopRow(
                    key: ValueKey(shop),
                    shop: shop,
                    isAvailable: available.contains(shop),
                    isSelected: isOn && shop == choice.chosen,
                    onTap: () => close(() => choice.matchAsYouTypeAt(shop)),
                  ),
                NestListRow(
                  key: const ValueKey('dontMatchAsYouType'),
                  title: CheckersCopy.dontMatchAsYouType,
                  leading: const Icon(LucideIcons.searchX),
                  isSelected: !isOn,
                  trailing: isOn ? null : const Icon(LucideIcons.check),
                  onTap: () =>
                      close(() => choice.setMatchesAsYouType(isOn: false)),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _ShopRow extends StatelessWidget {
  const _ShopRow({
    required this.shop,
    required this.isAvailable,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ProductRetailer shop;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => NestListRow(
    title: isAvailable
        ? CheckersCopy.matchAt(shop)
        : CheckersCopy.retailerSoon(shop),
    leading: RetailerLogo.decorative(
      retailer: shop,
      tone: isAvailable ? NestLogoTileTone.idle : NestLogoTileTone.muted,
    ),
    isSelected: isSelected,
    trailing: isSelected ? const Icon(LucideIcons.check) : null,
    onTap: isAvailable ? onTap : null,
  );
}
