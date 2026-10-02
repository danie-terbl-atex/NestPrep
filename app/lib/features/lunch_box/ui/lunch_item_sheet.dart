import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/allergen.dart';
import '../../family_profiles/ui/sheet_label.dart';
import '../model/lunch_item.dart';
import '../model/lunch_item_draft.dart';
import '../model/lunch_slot.dart';

/// Adds a library item, or edits one. With [fixedSlot] the slot is already
/// known — the person came from that compartment's picker — and is not asked.
/// An existing item keeps its slot: it is already in boxes under it.
///
/// "What is in it" is the part that matters: those ticks are what the app and
/// the rules check every box against (lunch-box ADR-0001).
Future<LunchItemDraft?> showLunchItemSheet({
  required BuildContext context,
  LunchItem? existing,
  LunchSlot? fixedSlot,
  String initialName = '',
  String? confirmLabel,
}) => showNestSheet<LunchItemDraft>(
  context: context,
  title: existing == null ? LunchCopy.newItemTitle : LunchCopy.editItemTitle,
  builder: (_) => _LunchItemBody(
    existing: existing,
    fixedSlot: existing?.slot ?? fixedSlot,
    initialName: existing?.name ?? initialName,
    confirmLabel:
        confirmLabel ??
        (existing == null ? LunchCopy.addItem : LunchCopy.saveItem),
  ),
);

class _LunchItemBody extends StatefulWidget {
  const _LunchItemBody({
    required this.existing,
    required this.fixedSlot,
    required this.initialName,
    required this.confirmLabel,
  });

  final LunchItem? existing;
  final LunchSlot? fixedSlot;
  final String initialName;
  final String confirmLabel;

  @override
  State<_LunchItemBody> createState() => _LunchItemBodyState();
}

class _LunchItemBodyState extends State<_LunchItemBody> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _prepNote = TextEditingController(
    text: widget.existing?.prepNote ?? '',
  );
  late LunchSlot _slot = widget.fixedSlot ?? LunchSlot.main;
  late final Set<Allergen> _allergens = {...?widget.existing?.knownAllergens};
  late bool _prepAhead = widget.existing?.prepAhead ?? false;

  @override
  void dispose() {
    _name.dispose();
    _prepNote.dispose();
    super.dispose();
  }

  LunchItemDraft get _draft => LunchItemDraft(
    name: _name.text,
    slot: _slot,
    allergens: {..._allergens},
    prepAhead: _prepAhead,
    prepNote: _prepNote.text,
  );

  @override
  Widget build(BuildContext context) {
    final isValid = _draft.isValid;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: LunchCopy.itemName,
            hint: LunchCopy.itemNameHint,
            controller: _name,
            autofocus: widget.existing == null && widget.initialName.isEmpty,
            textInputAction: TextInputAction.done,
            errorText: _name.text.trim().length > LunchItem.nameLimit
                ? LunchCopy.itemNameTooLong
                : null,
            onChanged: (_) => setState(() {}),
          ),
          if (widget.fixedSlot == null) ...[
            const SizedBox(height: NestSpace.xl),
            const SheetLabel(LunchCopy.itemSlot),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final slot in LunchSlot.values)
                  NestChip(
                    label: LunchCopy.slotName(slot),
                    isSelected: _slot == slot,
                    onTap: () => setState(() => _slot = slot),
                  ),
              ],
            ),
          ],
          const SizedBox(height: NestSpace.xl),
          const SheetLabel(LunchCopy.itemContains),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final allergen in Allergen.values)
                NestChip(
                  label: FamilyCopy.allergenName(allergen),
                  isSelected: _allergens.contains(allergen),
                  icon: _allergens.contains(allergen)
                      ? LucideIcons.check
                      : null,
                  onTap: () => setState(
                    () => _allergens.contains(allergen)
                        ? _allergens.remove(allergen)
                        : _allergens.add(allergen),
                  ),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            LunchCopy.itemContainsHelp,
            style: NestTheme.of(context).text.caption,
          ),
          const SizedBox(height: NestSpace.xl),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: NestChip(
              label: LunchCopy.itemPrepAhead,
              icon: LucideIcons.soup,
              isSelected: _prepAhead,
              onTap: () => setState(() => _prepAhead = !_prepAhead),
            ),
          ),
          if (_prepAhead) ...[
            const SizedBox(height: NestSpace.md),
            NestTextField(
              label: LunchCopy.itemPrepNote,
              hint: LunchCopy.itemPrepNoteHint,
              controller: _prepNote,
              errorText: _prepNote.text.trim().length > LunchItem.prepNoteLimit
                  ? LunchCopy.itemPrepNoteTooLong
                  : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: widget.confirmLabel,
            onPressed: isValid ? () => Navigator.of(context).pop(_draft) : null,
          ),
        ],
      ),
    );
  }
}
