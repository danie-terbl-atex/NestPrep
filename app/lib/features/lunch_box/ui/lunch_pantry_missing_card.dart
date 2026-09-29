import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/lunch_pantry_week.dart';
import '../state/lunch_pantry_controller.dart';
import 'art/lunch_glyph.dart';

/// What the week's boxes from today on still need that the house does not
/// have, and the one button that puts it on the grocery list (lunch-box
/// ADR-0006). Says so, rather than offering the button, to somebody who
/// cannot add to groceries.
class LunchPantryMissingCard extends StatefulWidget {
  const LunchPantryMissingCard({
    required this.week,
    required this.canAddGroceries,
    super.key,
  });

  final LunchPantryWeek week;
  final bool canAddGroceries;

  @override
  State<LunchPantryMissingCard> createState() => _LunchPantryMissingCardState();
}

class _LunchPantryMissingCardState extends State<LunchPantryMissingCard> {
  /// What the last send added — said once, in place.
  int? _added;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final pantry = context.watch<LunchPantryController>();
    final shortfall = widget.week.shortfall;
    final added = _added;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(LunchPantryCopy.missingTitle, style: nest.text.title),
          const SizedBox(height: NestSpace.sm),
          if (shortfall.isEmpty)
            Text(
              LunchPantryCopy.nothingMissing,
              style: nest.text.bodySecondary,
            ),
          for (final missing in shortfall)
            NestListRow(
              key: ValueKey(missing.item.id),
              title: missing.item.name,
              subtitle: LunchPantryCopy.needsBoxes(missing.boxes),
              leading: switch (missing.item.slot) {
                null => null,
                final slot => LunchSlotTile(slot: slot),
              },
            ),
          if (added != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestBanner(
              message: LunchPantryCopy.addedToGroceries(added),
              tone: NestBannerTone.success,
            ),
          ],
          if (shortfall.isNotEmpty) ...[
            const SizedBox(height: NestSpace.md),
            if (widget.canAddGroceries)
              NestButton(
                label: LunchPantryCopy.addMissingToGroceries(shortfall.length),
                icon: Icons.add_shopping_cart_rounded,
                isLoading: pantry.isSending,
                onPressed: () => _send(pantry),
              )
            else
              Text(
                LunchPantryCopy.groceriesNotShared,
                style: nest.text.bodySecondary,
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _send(LunchPantryController pantry) async {
    final added = await pantry.sendShortfallToGroceries(
      quantityFor: LunchPantryCopy.forBoxes,
    );
    if (!mounted || added == null) return;
    setState(() => _added = added);
  }
}
