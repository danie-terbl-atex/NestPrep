import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/money/money.dart';
import '../../../shared/money/money_input.dart';
import '../../family_profiles/ui/sheet_outcome.dart';
import '../model/lunch_cost.dart';
import '../model/lunch_price.dart';

/// A price as typed: what was paid, and how many boxes it does.
typedef LunchPriceEntry = ({int cents, int portions});

/// What one thing costs (lunch-box ADR-0007): per box, or per pack with how
/// many boxes the pack does — and, before saving, what that works out at a
/// box, so nothing is divided behind anybody's back (`FE-10`).
Future<SheetOutcome<LunchPriceEntry>?> showLunchPriceSheet({
  required BuildContext context,
  required String itemName,
  LunchPrice? existing,
}) => showNestSheet<SheetOutcome<LunchPriceEntry>>(
  context: context,
  title: itemName,
  builder: (_) => _PriceBody(existing: existing),
);

class _PriceBody extends StatefulWidget {
  const _PriceBody({required this.existing});

  final LunchPrice? existing;

  @override
  State<_PriceBody> createState() => _PriceBodyState();
}

class _PriceBodyState extends State<_PriceBody> {
  late bool _isPack = widget.existing?.isPack ?? false;
  late final _amount = TextEditingController(
    text: switch (widget.existing) {
      null => '',
      final price => MoneyInput.edit(price.money),
    },
  );
  late final _boxes = TextEditingController(
    text: '${widget.existing?.portions ?? 8}',
  );

  Money? get _money => MoneyInput.parse(_amount.text);

  bool get _isAmountValid {
    final money = _money;
    return money != null && money.cents <= LunchPrice.centsLimit;
  }

  int? get _portions {
    if (!_isPack) return 1;
    final value = int.tryParse(_boxes.text.trim());
    if (value == null || value < 1 || value > LunchPrice.portionLimit) {
      return null;
    }
    return value;
  }

  @override
  void dispose() {
    _amount.dispose();
    _boxes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final money = _money;
    final portions = _portions;
    final canSave = _isAmountValid && portions != null;
    return ListView(
      shrinkWrap: true,
      children: [
        Text(LunchBudgetCopy.priceSheetTitle, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.md),
        Wrap(
          spacing: NestSpace.sm,
          children: [
            for (final (label, isPack) in const [
              (LunchBudgetCopy.byBox, false),
              (LunchBudgetCopy.byPack, true),
            ])
              NestChip(
                label: label,
                isSelected: _isPack == isPack,
                onTap: () => setState(() => _isPack = isPack),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.lg),
        NestTextField(
          label: _isPack
              ? LunchBudgetCopy.amountPerPack
              : LunchBudgetCopy.amountPerBox,
          hint: LunchBudgetCopy.amountHint,
          controller: _amount,
          prefixIcon: LucideIcons.banknote,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _amount.text.isNotEmpty && !_isAmountValid
              ? LunchBudgetCopy.amountInvalid
              : null,
          onChanged: (_) => setState(() {}),
        ),
        if (_isPack) ...[
          const SizedBox(height: NestSpace.lg),
          NestTextField(
            label: LunchBudgetCopy.packBoxes,
            hint: LunchBudgetCopy.packBoxesHint,
            controller: _boxes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: portions == null ? LunchBudgetCopy.boxesInvalid : null,
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_isPack && canSave && money != null) ...[
          const SizedBox(height: NestSpace.md),
          Text(
            LunchBudgetCopy.worksOutAt(
              LunchCost.share(
                cents: money.cents,
                portions: portions,
              ).money.display,
            ),
            style: nest.text.bodyStrong,
          ),
        ],
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: LunchBudgetCopy.savePrice,
          onPressed: canSave && money != null
              ? () => Navigator.of(context).pop(
                  SheetSaved<LunchPriceEntry>((
                    cents: money.cents,
                    portions: portions,
                  )),
                )
              : null,
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: LunchBudgetCopy.removePrice,
            variant: NestButtonVariant.ghost,
            onPressed: () => Navigator.of(
              context,
            ).pop(const SheetRemoved<LunchPriceEntry>()),
          ),
        ],
      ],
    );
  }
}
