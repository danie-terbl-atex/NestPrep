import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/copy/photo_frame_copy.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../add_to_checkers/data/checkers_area_preference.dart';
import '../../add_to_checkers/data/retailer_preference.dart';
import '../../add_to_checkers/model/checkers_area.dart';
import '../../add_to_checkers/model/retailer_switch.dart';
import '../../groceries/model/product_match.dart';
import '../model/frame_groceries.dart';

/// [FrameGroceriesEditor] with what it offers read from the app: the shops
/// switched on, and the shop and area this phone last chose for [householdId],
/// which a frame switched on starts at.
class FrameGroceriesSection extends StatefulWidget {
  const FrameGroceriesSection({
    required this.householdId,
    required this.groceries,
    required this.onChanged,
    super.key,
  });

  final String householdId;
  final FrameGroceries? groceries;
  final ValueChanged<FrameGroceries?>? onChanged;

  @override
  State<FrameGroceriesSection> createState() => _FrameGroceriesSectionState();
}

class _FrameGroceriesSectionState extends State<FrameGroceriesSection> {
  late final Future<({CheckersArea? area, ProductRetailer? shop})>
  _phoneChoice = _readPhoneChoice(
    widget.householdId,
    areas: context.read<CheckersAreaPreference?>(),
    shops: context.read<RetailerPreference?>(),
  );

  static Future<({CheckersArea? area, ProductRetailer? shop})> _readPhoneChoice(
    String householdId, {
    required CheckersAreaPreference? areas,
    required RetailerPreference? shops,
  }) async => (
    area: await areas?.read(householdId),
    shop: await shops?.read(householdId),
  );

  @override
  Widget build(BuildContext context) {
    final flags = context.watch<FeatureFlagsController?>();
    return FutureBuilder(
      future: _phoneChoice,
      builder: (context, phoneChoice) => FrameGroceriesEditor(
        groceries: widget.groceries,
        shopsOn: flags == null ? const [] : shopsOn(flags.isOn),
        defaultShop: phoneChoice.data?.shop,
        defaultArea: phoneChoice.data?.area ?? CheckersArea.fallback,
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// *Add groceries from the frame*, and the shop and area it picks products
/// at. Offered while a shop is switched on; a frame already adding keeps its
/// shop, offered or not, until somebody switches it off. Switched on, it
/// starts at [defaultShop] when that is offered.
class FrameGroceriesEditor extends StatelessWidget {
  const FrameGroceriesEditor({
    required this.groceries,
    required this.shopsOn,
    required this.defaultShop,
    required this.defaultArea,
    required this.onChanged,
    super.key,
  });

  final FrameGroceries? groceries;
  final List<ProductRetailer> shopsOn;
  final ProductRetailer? defaultShop;
  final CheckersArea defaultArea;
  final ValueChanged<FrameGroceries?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final current = groceries;
    final shops = [
      for (final shop in ProductRetailer.values)
        if (shopsOn.contains(shop) || shop == current?.shop) shop,
    ];
    if (shops.isEmpty) return const SizedBox.shrink();
    final nest = NestTheme.of(context);
    final change = onChanged;
    final startShop = switch (defaultShop) {
      final shop? when shops.contains(shop) => shop,
      _ => shops.first,
    };
    void toggle(bool on) => change?.call(
      on ? FrameGroceries(shop: startShop, area: defaultArea) : null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestListRow(
          title: PhotoFrameCopy.groceries,
          subtitle: PhotoFrameCopy.groceriesBody,
          leading: const NestIconTile(
            icon: LucideIcons.shoppingBasket,
            tint: NestTileTint.guava,
            size: NestSize.avatarMedium,
          ),
          trailing: Semantics(
            label: PhotoFrameCopy.groceries,
            child: Switch(
              value: current != null,
              onChanged: change == null ? null : toggle,
            ),
          ),
          onTap: change == null ? null : () => toggle(current == null),
        ),
        if (current != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpace.lg,
              NestSpace.xs,
              NestSpace.lg,
              NestSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(PhotoFrameCopy.groceriesShop, style: nest.text.caption),
                const SizedBox(height: NestSpace.sm),
                Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.sm,
                  children: [
                    for (final shop in shops)
                      NestChip(
                        key: ValueKey(shop),
                        label: CheckersCopy.retailerName(shop),
                        isSelected: shop == current.shop,
                        onTap: change == null
                            ? null
                            : () => change(current.copyWith(shop: shop)),
                      ),
                  ],
                ),
                const SizedBox(height: NestSpace.md),
                Text(PhotoFrameCopy.groceriesArea, style: nest.text.caption),
                const SizedBox(height: NestSpace.sm),
                Wrap(
                  spacing: NestSpace.sm,
                  runSpacing: NestSpace.sm,
                  children: [
                    for (final area in CheckersArea.values)
                      NestChip(
                        key: ValueKey(area),
                        label: area.label,
                        isSelected: area == current.area,
                        onTap: change == null
                            ? null
                            : () => change(current.copyWith(area: area)),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
