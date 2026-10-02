import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/copy/checkers_copy.dart';
import '../../groceries/model/grocery_item.dart';
import '../../groceries/model/product_match.dart';
import '../state/product_match_controller.dart';
import '../state/retailer_choice_controller.dart';
import 'retailer_logo.dart';

/// *Find at Checkers* beside an unbought item nobody has matched yet: the
/// chosen shop's own logo, so the tap says where it will look.
///
/// Steps aside while this item's matches are already open under it — the
/// panel is the answer to the button, so showing both invites a second tap.
/// Selects only whether this item is the target and the chosen shop
/// (`FE-12`).
class FindAtCheckersButton extends StatelessWidget {
  const FindAtCheckersButton({required this.item, super.key});

  final GroceryItem item;

  @override
  Widget build(BuildContext context) {
    final isOpen = context.select<ProductMatchController, bool>(
      (controller) => controller.target?.itemId == item.id,
    );
    if (isOpen) return const SizedBox.shrink();
    final retailer = context.select<RetailerChoiceController, ProductRetailer>(
      (choice) => choice.chosen,
    );
    return RetailerLogo(
      retailer: retailer,
      label: CheckersCopy.findAt(retailer),
      onTap: () => context.read<ProductMatchController>().lookFor(item),
    );
  }
}
