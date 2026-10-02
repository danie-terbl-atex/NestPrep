import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/handover_note.dart';

/// What is in the bag (household ADR-0004): a tick per thing, a way to add
/// one, and the usual things offered with a tap so a handover takes seconds.
/// It edits a list and hands it back; saving is the screen's.
class BagChecklist extends StatefulWidget {
  const BagChecklist({
    required this.items,
    required this.canEdit,
    required this.onChanged,
    super.key,
  });

  final List<HandoverItem> items;
  final bool canEdit;
  final ValueChanged<List<HandoverItem>> onChanged;

  @override
  State<BagChecklist> createState() => _BagChecklistState();
}

class _BagChecklistState extends State<BagChecklist> {
  final _newItem = TextEditingController();

  @override
  void dispose() {
    _newItem.dispose();
    super.dispose();
  }

  bool get _isFull => widget.items.length >= HandoverNote.maxItems;

  void _add(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isFull) return;
    final exists = widget.items.any(
      (item) => item.text.toLowerCase() == trimmed.toLowerCase(),
    );
    if (!exists) {
      widget.onChanged([
        ...widget.items,
        HandoverItem(text: trimmed, packed: false),
      ]);
    }
    _newItem.clear();
  }

  void _toggle(int index) => widget.onChanged([
    for (var each = 0; each < widget.items.length; each++)
      each == index
          ? widget.items[each].copyWith(packed: !widget.items[each].packed)
          : widget.items[each],
  ]);

  void _remove(int index) =>
      widget.onChanged([...widget.items]..removeAt(index));

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final items = widget.items;
    final have = {for (final item in items) item.text.toLowerCase()};
    final suggestions = [
      for (final text in TwoHomesHandoverCopy.suggestions)
        if (!have.contains(text.toLowerCase())) text,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: TwoHomesHandoverCopy.inTheBag),
        if (items.isNotEmpty)
          Text(
            TwoHomesHandoverCopy.packedCount(
              items.where((item) => item.packed).length,
              items.length,
            ),
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
        const SizedBox(height: NestSpace.sm),
        for (var index = 0; index < items.length; index++)
          Padding(
            key: ValueKey('bag_${items[index].text}'),
            padding: const EdgeInsets.only(bottom: NestSpace.xs),
            child: _BagItemRow(
              item: items[index],
              onToggle: widget.canEdit ? () => _toggle(index) : null,
              onRemove: widget.canEdit ? () => _remove(index) : null,
            ),
          ),
        if (widget.canEdit && !_isFull) ...[
          const SizedBox(height: NestSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: NestTextField(
                  label: TwoHomesHandoverCopy.itemLabel,
                  hint: TwoHomesHandoverCopy.itemHint,
                  controller: _newItem,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(HandoverItem.maxLength),
                  ],
                  onSubmitted: _add,
                ),
              ),
              const SizedBox(width: NestSpace.sm),
              NestIconButton(
                icon: LucideIcons.plus,
                label: TwoHomesHandoverCopy.addItem,
                variant: NestIconButtonVariant.accent,
                onPressed: () => _add(_newItem.text),
              ),
            ],
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: NestSpace.md),
            Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                for (final text in suggestions)
                  NestChip(
                    label: text,
                    icon: LucideIcons.plus,
                    onTap: () => _add(text),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// One thing in the bag: a tick that is its own node to a screen reader,
/// the words struck through once packed, and a way to take it off the list.
class _BagItemRow extends StatelessWidget {
  const _BagItemRow({
    required this.item,
    required this.onToggle,
    required this.onRemove,
  });

  final HandoverItem item;
  final VoidCallback? onToggle;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final remove = onRemove;
    return NestCard(
      variant: item.packed ? NestCardVariant.tinted : NestCardVariant.flat,
      padding: const EdgeInsets.symmetric(horizontal: NestSpace.md),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              checked: item.packed,
              label: item.text,
              excludeSemantics: true,
              onTap: onToggle,
              child: InkWell(
                onTap: onToggle,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: NestSize.touchTarget,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.packed
                            ? LucideIcons.circleCheck
                            : LucideIcons.circle,
                        color: item.packed
                            ? nest.colors.success
                            : nest.colors.inkTertiary,
                        size: NestSize.iconLarge,
                      ),
                      const SizedBox(width: NestSpace.md),
                      Expanded(
                        child: Text(
                          item.text,
                          style: nest.text.body.copyWith(
                            decoration: item.packed
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.packed
                                ? nest.colors.inkSecondary
                                : nest.colors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (remove != null)
            NestIconButton(
              icon: LucideIcons.x,
              label: '${TwoHomesHandoverCopy.removeItem} ${item.text}',
              variant: NestIconButtonVariant.plain,
              onPressed: remove,
            ),
        ],
      ),
    );
  }
}
