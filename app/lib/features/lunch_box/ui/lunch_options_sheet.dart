import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/ui/sheet_outcome.dart';
import '../model/lunch_choices.dart';
import '../model/lunch_item.dart';
import '../model/lunch_pick.dart';
import '../model/lunch_slot.dart';
import '../model/lunch_suggestions.dart';
import 'art/lunch_glyph.dart';
import 'lunch_suggestion_row.dart';

/// Two or three options for one compartment on one day (lunch-box
/// ADR-0008), chosen from the child's *suggested* items only — so nothing
/// unsafe or disliked can be offered — best first, with why.
Future<SheetOutcome<List<LunchItem>>?> showLunchOptionsSheet({
  required BuildContext context,
  required LunchSlot slot,
  required String dayName,
  required RankedLunchItems ranked,
  required List<LunchPick> current,
}) => showNestSheet<SheetOutcome<List<LunchItem>>>(
  context: context,
  title: LunchKidPicksCopy.optionsTitle(LunchCopy.slotName(slot), dayName),
  builder: (_) => _OptionsBody(slot: slot, ranked: ranked, current: current),
);

class _OptionsBody extends StatefulWidget {
  const _OptionsBody({
    required this.slot,
    required this.ranked,
    required this.current,
  });

  final LunchSlot slot;
  final RankedLunchItems ranked;
  final List<LunchPick> current;

  @override
  State<_OptionsBody> createState() => _OptionsBodyState();
}

class _OptionsBodyState extends State<_OptionsBody> {
  late final Set<String> _chosen = {
    for (final pick in widget.current)
      if (widget.ranked.suggested.any((s) => s.item.id == pick.itemId))
        pick.itemId,
  };

  void _toggle(String itemId) => setState(() {
    if (!_chosen.remove(itemId) && _chosen.length < LunchChoices.mostOptions) {
      _chosen.add(itemId);
    }
  });

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final suggested = widget.ranked.suggested;
    final canSave = _chosen.length >= LunchChoices.fewestOptions;
    return ListView(
      shrinkWrap: true,
      children: [
        Text(LunchKidPicksCopy.optionsHelp, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.xs),
        Text(
          LunchKidPicksCopy.optionsCount(_chosen.length),
          style: nest.text.bodyStrong,
        ),
        if (suggested.length < LunchChoices.fewestOptions) ...[
          const SizedBox(height: NestSpace.lg),
          Text(LunchKidPicksCopy.noSuggestions, style: nest.text.body),
        ],
        for (final entry in suggested)
          Semantics(
            key: ValueKey(entry.item.id),
            checked: _chosen.contains(entry.item.id),
            child: NestListRow(
              title: entry.item.name,
              subtitle: suggestionReasons(entry).join(' · '),
              isSelected: _chosen.contains(entry.item.id),
              leading: LunchSlotTile(slot: widget.slot),
              trailing: Icon(
                _chosen.contains(entry.item.id)
                    ? LucideIcons.circleCheck
                    : LucideIcons.circle,
                color: _chosen.contains(entry.item.id)
                    ? nest.colors.accent
                    : nest.colors.outlineStrong,
                size: NestSize.iconLarge,
              ),
              onTap: () => _toggle(entry.item.id),
            ),
          ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: LunchKidPicksCopy.saveOptions,
          onPressed: canSave
              ? () => Navigator.of(context).pop(
                  SheetSaved<List<LunchItem>>([
                    for (final entry in suggested)
                      if (_chosen.contains(entry.item.id)) entry.item,
                  ]),
                )
              : null,
        ),
        if (widget.current.isNotEmpty) ...[
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: LunchKidPicksCopy.clearOptions,
            variant: NestButtonVariant.ghost,
            onPressed: () =>
                Navigator.of(context)
                    .pop(const SheetRemoved<List<LunchItem>>()),
          ),
        ],
      ],
    );
  }
}
