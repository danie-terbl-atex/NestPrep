import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/meal_ingredient_copy.dart';
import '../../meal_planning/model/ingredient_amount.dart';
import '../../meal_planning/model/ingredient_unit.dart';
import '../model/own_recipe_limits.dart';
import '../model/recipe_form.dart';

/// With no [line] it adds, staying open for the next one until [canAddMore]
/// says no; with one it changes that line.
Future<void> showRecipeLineSheet({
  required BuildContext context,
  required ValueChanged<RecipeFormLine> onSubmit,
  RecipeFormLine? line,
  bool Function()? canAddMore,
}) => showNestSheet<void>(
  context: context,
  title: line == null
      ? OwnRecipeCopy.addIngredient
      : OwnRecipeCopy.editIngredient,
  builder: (_) =>
      _RecipeLineForm(line: line, canAddMore: canAddMore, onSubmit: onSubmit),
);

enum _AmountProblem { notAnAmount, tooBig }

class _RecipeLineForm extends StatefulWidget {
  const _RecipeLineForm({
    required this.line,
    required this.canAddMore,
    required this.onSubmit,
  });

  final RecipeFormLine? line;
  final bool Function()? canAddMore;
  final ValueChanged<RecipeFormLine> onSubmit;

  @override
  State<_RecipeLineForm> createState() => _RecipeLineFormState();
}

class _RecipeLineFormState extends State<_RecipeLineForm> {
  late final _name = TextEditingController(text: widget.line?.name ?? '');
  late final _amount = TextEditingController(
    text: switch (widget.line?.amount) {
      final amount? when amount == amount.roundToDouble() =>
        '${amount.toInt()}',
      final amount? => '$amount',
      null => '',
    },
  );
  late final _note = TextEditingController(text: widget.line?.note ?? '');
  final _nameFocus = FocusNode();
  late IngredientUnit? _unit = widget.line?.unit;
  _AmountProblem? _amountProblem;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final double? amount;
    try {
      amount = parseIngredientAmount(_amount.text);
    } on FormatException {
      setState(() => _amountProblem = _AmountProblem.notAnAmount);
      return;
    }
    if (amount != null && amount > OwnRecipeLimits.quantity) {
      setState(() => _amountProblem = _AmountProblem.tooBig);
      return;
    }
    final note = _note.text.trim();
    widget.onSubmit(
      RecipeFormLine(
        id: widget.line?.id ?? '',
        name: _name.text.trim(),
        amount: amount,
        unit: amount == null ? null : _unit,
        note: note.isEmpty ? null : note,
      ),
    );
    if (widget.canAddMore?.call() ?? false) {
      _name.clear();
      _amount.clear();
      _note.clear();
      setState(() => _unit = null);
      _nameFocus.requestFocus();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final addsMore = widget.canAddMore != null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            key: const ValueKey('recipe-line-name'),
            label: MealIngredientCopy.name,
            hint: MealIngredientCopy.nameHint,
            controller: _name,
            focusNode: _nameFocus,
            autofocus: true,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              LengthLimitingTextInputFormatter(OwnRecipeLimits.ingredientName),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.md),
          NestTextField(
            key: const ValueKey('recipe-line-amount'),
            label: MealIngredientCopy.amount,
            hint: MealIngredientCopy.amountHint,
            controller: _amount,
            errorText: switch (_amountProblem) {
              _AmountProblem.notAnAmount => MealIngredientCopy.amountInvalid,
              _AmountProblem.tooBig => OwnRecipeCopy.amountTooBig,
              null => null,
            },
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() => _amountProblem = null),
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
          const SizedBox(height: NestSpace.md),
          NestTextField(
            key: const ValueKey('recipe-line-note'),
            label: OwnRecipeCopy.ingredientNote,
            hint: OwnRecipeCopy.ingredientNoteHint,
            controller: _note,
            inputFormatters: [
              LengthLimitingTextInputFormatter(OwnRecipeLimits.ingredientNote),
            ],
          ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            key: const ValueKey('recipe-line-submit'),
            label: addsMore
                ? MealIngredientCopy.add
                : OwnRecipeCopy.saveIngredient,
            icon: addsMore ? LucideIcons.plus : null,
            variant: addsMore
                ? NestButtonVariant.tonal
                : NestButtonVariant.primary,
            onPressed: _name.text.trim().isEmpty ? null : _submit,
          ),
          if (addsMore) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              key: const ValueKey('recipe-line-done'),
              label: OwnRecipeCopy.done,
              variant: NestButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}
