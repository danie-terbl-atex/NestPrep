import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../recipes/model/recipe.dart';
import '../model/fill_week_box.dart';
import '../model/lunch_concern.dart';
import '../model/lunch_slot.dart';
import 'art/lunch_glyph.dart';
import 'lunch_concern_tags.dart';

/// One box on offer in *Fill the week*: its name, what it is, each
/// compartment — a recipe opens to show how it is made — and the choice to
/// take it, numbered by its turn once chosen. A ready-made compartment that
/// is not right for the child says NestPrep fills it instead, and why; a
/// go-to box with anything unsafe says so and cannot be chosen
/// ([onToggle] is null).
class FillWeekBoxCard extends StatelessWidget {
  const FillWeekBoxCard({
    required this.box,
    required this.turn,
    required this.childName,
    required this.onToggle,
    required this.onOpenRecipe,
    super.key,
  });

  final FillWeekBox box;

  /// Its place in the turns, from 1, or null when it is not chosen.
  final int? turn;
  final String childName;
  final VoidCallback? onToggle;
  final ValueChanged<Recipe> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final turn = this.turn;
    return NestCard(
      variant: turn != null ? NestCardVariant.tinted : NestCardVariant.raised,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(box.name, style: nest.text.title),
          if (box.blurb.isNotEmpty) ...[
            const SizedBox(height: NestSpace.xs),
            Text(box.blurb, style: nest.text.bodySecondary),
          ],
          const SizedBox(height: NestSpace.sm),
          for (final compartment in box.compartments)
            _CompartmentRow(
              key: ValueKey('fill-week-${box.id}-${compartment.slot.name}'),
              compartment: compartment,
              isReadyMade: box.isReadyMade,
              onOpenRecipe: onOpenRecipe,
            ),
          const SizedBox(height: NestSpace.sm),
          if (onToggle == null)
            NestTag(
              label: FillWeekCopy.notSafeAnyMore(childName),
              tone: NestTagTone.danger,
              icon: LucideIcons.ban,
            )
          else
            NestChip(
              key: ValueKey('fill-week-box-${box.id}'),
              label: turn == null
                  ? FillWeekCopy.choose
                  : FillWeekCopy.chosenTurn(turn),
              isSelected: turn != null,
              icon: turn == null ? LucideIcons.plus : LucideIcons.check,
              semanticLabel: turn == null
                  ? FillWeekCopy.chooseBox(box.name)
                  : FillWeekCopy.unchooseBox(box.name),
              onTap: onToggle,
            ),
        ],
      ),
    );
  }
}

class _CompartmentRow extends StatelessWidget {
  const _CompartmentRow({
    required this.compartment,
    required this.isReadyMade,
    required this.onOpenRecipe,
    super.key,
  });

  final FillWeekCompartment compartment;
  final bool isReadyMade;
  final ValueChanged<Recipe> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final recipe = compartment.recipe;
    final slot = compartment.slot;
    return NestListRow(
      leading: LunchSlotTile(
        slot: slot,
        size: NestSize.avatarSmall,
        isEmpty: !compartment.isSafe,
      ),
      title: compartment.pick.name,
      subtitle: [
        LunchCopy.slotName(slot),
        if (isReadyMade)
          switch (compartment) {
            FillWeekCompartment(recipe: _?) => FillWeekCopy.recipeOpen,
            FillWeekCompartment(isRecipe: true) => FillWeekCopy.recipe,
            _ => FillWeekCopy.quickPick,
          },
        if (isReadyMade && slot == LunchSlot.treat) FillWeekCopy.fridayOnly,
      ].join(' · '),
      trailing: recipe == null ? null : const Icon(LucideIcons.chevronRight),
      onTap: recipe == null ? null : () => onOpenRecipe(recipe),
      footer: compartment.isSafe ? null : _Unsafe(compartment, isReadyMade),
    );
  }
}

class _Unsafe extends StatelessWidget {
  const _Unsafe(this.compartment, this.isReadyMade);

  final FillWeekCompartment compartment;
  final bool isReadyMade;

  @override
  Widget build(BuildContext context) {
    if (!isReadyMade) return LunchConcernTags(concerns: compartment.unsafe);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: NestTag(
        label: FillWeekCopy.willFillInstead(
          compartment.unsafe.map(_contains).toSet().join(', '),
        ),
        tone: NestTagTone.warning,
        icon: LucideIcons.refreshCw,
      ),
    );
  }

  static String _contains(LunchConcern concern) => switch (concern) {
    AllergenConcern(:final allergen) => FamilyCopy.allergenName(
      allergen,
    ).toLowerCase(),
    NutRuleConcern() => FillWeekCopy.nuts,
    DislikeConcern(:final dislike) => dislike,
  };
}
