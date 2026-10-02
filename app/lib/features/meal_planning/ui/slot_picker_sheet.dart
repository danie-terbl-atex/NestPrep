import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/meal_ingredient_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/text/normalised_name.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/meal.dart';
import '../model/week_plan.dart';

/// What the picker came back with.
sealed class SlotChoice {
  const SlotChoice();
}

/// A meal already in the household's library.
final class SlotPicked extends SlotChoice {
  const SlotPicked(this.mealId);

  final String mealId;
}

/// A name somebody typed. It joins the library if the household has not typed
/// it before (meal-planning ADR-0001).
final class SlotTyped extends SlotChoice {
  const SlotTyped(this.name);

  final String name;
}

final class SlotCleared extends SlotChoice {
  const SlotCleared();
}

/// Open what goes in the meal already in the slot (meal-planning ADR-0002).
final class SlotIngredients extends SlotChoice {
  const SlotIngredients();
}

Future<SlotChoice?> showSlotPickerSheet({
  required BuildContext context,
  required MealSlot slot,
  required CalendarDate date,
  required CalendarDate today,
  required List<Meal> library,
  Meal? current,
}) => showNestSheet<SlotChoice>(
  context: context,
  title:
      '${AppCopy.mealSlotName(slot.name)} · '
      '${NestDates.relative(date, today)}',
  builder: (sheetContext) =>
      _SlotPickerBody(library: library, current: current),
);

class _SlotPickerBody extends StatefulWidget {
  const _SlotPickerBody({required this.library, required this.current});

  final List<Meal> library;
  final Meal? current;

  @override
  State<_SlotPickerBody> createState() => _SlotPickerBodyState();
}

class _SlotPickerBodyState extends State<_SlotPickerBody> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The library, narrowed as somebody types — so a household with forty meals
  /// still finds Spaghetti in three letters (`FE-11`).
  List<Meal> get _matches {
    final typed = normalisedName(_name.text);
    if (typed.isEmpty) return widget.library;
    return [
      for (final meal in widget.library)
        if (meal.nameKey.contains(typed)) meal,
    ];
  }

  bool get _typedIsNew =>
      _name.text.trim().isNotEmpty &&
      !widget.library.any((meal) => meal.nameKey == normalisedName(_name.text));

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final matches = _matches;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestTextField(
          label: AppCopy.mealsPickTitle,
          hint: AppCopy.mealsTypeHint,
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _useTyped(),
        ),
        if (_typedIsNew) ...[
          const SizedBox(height: NestSpace.md),
          NestButton(
            label: '${AppCopy.groceriesAdd} “${_name.text.trim()}”',
            icon: LucideIcons.plus,
            onPressed: _useTyped,
          ),
        ],
        if (matches.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xl),
          Text(
            AppCopy.mealsLibrary,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final meal in matches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NestSpace.xs),
                    child: NestListRow(
                      key: ValueKey(meal.id),
                      title: meal.name,
                      isSelected: meal.id == widget.current?.id,
                      onTap: () =>
                          Navigator.of(context).pop(SlotPicked(meal.id)),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (widget.current case final current?) ...[
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: MealIngredientCopy.whatGoesIn,
            icon: LucideIcons.shoppingBasket,
            variant: NestButtonVariant.tonal,
            onPressed: () => Navigator.of(context).pop(const SlotIngredients()),
          ),
          Padding(
            padding: const EdgeInsets.only(top: NestSpace.xs),
            child: Text(
              MealIngredientCopy.count(current.ingredients.length),
              textAlign: TextAlign.center,
              style: nest.text.caption,
            ),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: AppCopy.mealsClearSlot,
            variant: NestButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(const SlotCleared()),
          ),
        ],
      ],
    );
  }

  void _useTyped() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(SlotTyped(_name.text));
  }
}
