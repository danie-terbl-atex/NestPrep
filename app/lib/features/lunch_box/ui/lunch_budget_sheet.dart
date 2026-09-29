import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/money/money.dart';
import '../../../shared/money/money_input.dart';
import '../../family_profiles/ui/sheet_outcome.dart';
import '../model/lunch_budget.dart';

/// The household's weekly lunch budget (lunch-box ADR-0007), in rand, for
/// every child's boxes together. Removing it turns the meter off.
Future<SheetOutcome<Money>?> showLunchBudgetSheet({
  required BuildContext context,
  LunchBudget? existing,
}) => showNestSheet<SheetOutcome<Money>>(
  context: context,
  title: LunchBudgetCopy.budgetSheetTitle,
  builder: (_) => _BudgetBody(existing: existing),
);

class _BudgetBody extends StatefulWidget {
  const _BudgetBody({required this.existing});

  final LunchBudget? existing;

  @override
  State<_BudgetBody> createState() => _BudgetBodyState();
}

class _BudgetBodyState extends State<_BudgetBody> {
  late final _amount = TextEditingController(
    text: switch (widget.existing) {
      null => '',
      final budget => MoneyInput.edit(budget.money),
    },
  );

  Money? get _valid {
    final money = MoneyInput.parse(_amount.text);
    if (money == null ||
        money.cents < LunchBudget.minimumCents ||
        money.cents > LunchBudget.centsLimit) {
      return null;
    }
    return money;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _valid;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: LunchBudgetCopy.budgetAmount,
          hint: LunchBudgetCopy.budgetHint,
          controller: _amount,
          autofocus: widget.existing == null,
          prefixIcon: Icons.savings_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _amount.text.isNotEmpty && valid == null
              ? LunchBudgetCopy.budgetInvalid
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.xxl),
        NestButton(
          label: LunchBudgetCopy.saveBudget,
          onPressed: valid == null
              ? null
              : () => Navigator.of(context).pop(SheetSaved<Money>(valid)),
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: LunchBudgetCopy.removeBudget,
            variant: NestButtonVariant.ghost,
            onPressed: () =>
                Navigator.of(context).pop(const SheetRemoved<Money>()),
          ),
        ],
      ],
    );
  }
}
