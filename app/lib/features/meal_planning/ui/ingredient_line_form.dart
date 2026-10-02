import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/meal_ingredient_copy.dart';
import '../model/ingredient_amount.dart';
import '../model/ingredient_unit.dart';
import '../model/meal_ingredient.dart';

/// Adds one line to a meal's ingredients (meal-planning ADR-0002): a name, how
/// much if anybody knows, and what it is measured in. An amount that is not a
/// number is said on the field, never silently dropped (`FE-10`); submitting
/// clears the form and keeps the name focused for the next line.
class IngredientLineForm extends StatefulWidget {
  const IngredientLineForm({required this.onAdd, super.key});

  final ValueChanged<MealIngredient> onAdd;

  @override
  State<IngredientLineForm> createState() => _IngredientLineFormState();
}

class _IngredientLineFormState extends State<IngredientLineForm> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _nameFocus = FocusNode();
  IngredientUnit? _unit;
  bool _amountIsWrong = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: MealIngredientCopy.name,
          hint: MealIngredientCopy.nameHint,
          controller: _name,
          focusNode: _nameFocus,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            LengthLimitingTextInputFormatter(MealIngredient.nameLimit),
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NestSpace.md),
        NestTextField(
          label: MealIngredientCopy.amount,
          hint: MealIngredientCopy.amountHint,
          controller: _amount,
          errorText: _amountIsWrong ? MealIngredientCopy.amountInvalid : null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _amountIsWrong = false),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: NestSpace.md),
        Text(
          MealIngredientCopy.unit,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final unit in [null, ...IngredientUnit.values])
              NestChip(
                label: MealIngredientCopy.unitName(unit),
                isSelected: _unit == unit,
                onTap: () => setState(() => _unit = unit),
              ),
          ],
        ),
        const SizedBox(height: NestSpace.lg),
        NestButton(
          label: MealIngredientCopy.add,
          icon: LucideIcons.plus,
          variant: NestButtonVariant.tonal,
          onPressed: _name.text.trim().isEmpty ? null : _submit,
        ),
      ],
    );
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final double? amount;
    try {
      amount = parseIngredientAmount(_amount.text);
    } on FormatException {
      setState(() => _amountIsWrong = true);
      return;
    }
    widget.onAdd(
      MealIngredient.typed(name: _name.text, amount: amount, unit: _unit),
    );
    _name.clear();
    _amount.clear();
    setState(() => _unit = null);
    _nameFocus.requestFocus();
  }
}
