import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/text/normalised_name.dart';
import '../model/lunch_item.dart';
import '../model/lunch_item_draft.dart';
import '../state/lunch_pantry_controller.dart';
import 'art/lunch_glyph.dart';
import 'lunch_item_sheet.dart';

/// Quick add (lunch-box ADR-0006): find a thing in the library and tap it —
/// a pack's worth goes in, and the sheet stays open for the next. Something
/// the library does not have is added to it first, with the item sheet
/// everything else uses.
Future<void> showLunchPantryAddSheet({
  required BuildContext context,
  required LunchPantryController pantry,
  required List<LunchItem> library,
}) => showNestSheet<void>(
  context: context,
  title: LunchPantryCopy.addTitle,
  // The sheet is a route of its own: the controller is handed across so each
  // row can say, live, what the pantry now holds.
  builder: (_) => ChangeNotifierProvider.value(
    value: pantry,
    child: _AddBody(library: library),
  ),
);

class _AddBody extends StatefulWidget {
  const _AddBody({required this.library});

  final List<LunchItem> library;

  @override
  State<_AddBody> createState() => _AddBodyState();
}

class _AddBodyState extends State<_AddBody> {
  var _query = '';

  List<LunchItem> get _matches {
    final key = normalisedName(_query);
    return [
      for (final item in widget.library)
        if (!item.archived && (key.isEmpty || item.nameKey.contains(key))) item,
    ]..sort((a, b) => a.nameKey.compareTo(b.nameKey));
  }

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<LunchPantryController>();
    final week = switch (pantry.pantry) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final matches = _matches;
    return ListView(
      shrinkWrap: true,
      children: [
        NestTextField(
          label: LunchPantryCopy.search,
          hint: LunchPantryCopy.searchHint,
          prefixIcon: Icons.search_rounded,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: LunchPantryCopy.somethingNew,
          icon: Icons.add_rounded,
          variant: NestButtonVariant.tonal,
          size: NestButtonSize.medium,
          onPressed: () => _addNew(context, pantry),
        ),
        if (matches.isEmpty) ...[
          const SizedBox(height: NestSpace.lg),
          Text(
            LunchPantryCopy.noMatch,
            style: NestTheme.of(context).text.bodySecondary,
          ),
        ],
        for (final item in matches)
          NestListRow(
            key: ValueKey(item.id),
            title: item.name,
            subtitle: week != null && week.has(item.id)
                ? '${LunchPantryCopy.alreadyIn} · '
                      '${LunchPantryCopy.enoughFor(week.stockOf(item.id))}'
                : LunchPantryCopy.aPack,
            leading: switch (item.slot) {
              null => null,
              final slot => LunchSlotTile(slot: slot),
            },
            trailing: Icon(
              Icons.add_circle_outline_rounded,
              color: NestTheme.of(context).colors.accent,
              size: NestSize.iconMedium,
            ),
            onTap: () => pantry.addPack(item.id),
          ),
      ],
    );
  }

  Future<void> _addNew(
    BuildContext context,
    LunchPantryController pantry,
  ) async {
    final LunchItemDraft? draft = await showLunchItemSheet(
      context: context,
      initialName: _query.trim(),
      confirmLabel: LunchPantryCopy.addToPantry,
    );
    if (draft == null) return;
    await pantry.addNewAndStock(draft);
  }
}
