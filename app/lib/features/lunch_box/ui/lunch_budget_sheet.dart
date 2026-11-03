import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/money/money.dart';
import '../../../shared/money/money_input.dart';
import '../../family_profiles/ui/sheet_outcome.dart';
import '../model/lunch_budget.dart';

/// The household's weekly lunch budget (lunch-box ADR-0007), in rand, for
/// every child's boxes together — the sheet names them, so nobody reads it as
/// per child. Removing it turns the meter off.
Future<SheetOutcome<Money>?> showLunchBudgetSheet({
  required BuildContext context,
  required List<String> childNames,
  LunchBudget? existing,
}) => showNestSheet<SheetOutcome<Money>>(
  context: context,
  title: LunchBudgetCopy.budgetSheetTitle,
  builder: (_) => _BudgetBody(existing: existing, childNames: childNames),
);

class _BudgetBody extends StatefulWidget {
  const _BudgetBody({required this.existing, required this.childNames});

  final LunchBudget? existing;
  final List<String> childNames;

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

  String? _perChild(Money? total) {
    final children = widget.childNames.length;
    if (total == null || children < 2) return null;
    final rand = (total.cents / children / 100).round();
    return LunchBudgetCopy.perChild(
      Money(rand * 100, currency: total.currency).displayShort,
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final valid = _valid;
    final perChild = _perChild(valid);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          LunchBudgetCopy.budgetFor(widget.childNames),
          style: nest.text.body,
        ),
        const SizedBox(height: NestSpace.lg),
        NestTextField(
          label: LunchBudgetCopy.budgetAmount,
          hint: LunchBudgetCopy.budgetHint,
          controller: _amount,
          autofocus: widget.existing == null,
          prefixIcon: LucideIcons.piggyBank,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          errorText: _amount.text.isNotEmpty && valid == null
              ? LunchBudgetCopy.budgetInvalid
              : null,
          onChanged: (_) => setState(() {}),
        ),
        if (perChild != null) ...[
          const SizedBox(height: NestSpace.sm),
          Text(perChild, style: nest.text.bodySecondary),
        ],
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
