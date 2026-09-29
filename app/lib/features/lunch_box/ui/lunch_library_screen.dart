import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../model/lunch_board.dart';
import '../model/lunch_item.dart';
import '../model/lunch_slot.dart';
import '../state/lunch_board_controller.dart';
import 'lunch_item_sheet.dart';
import 'lunch_library_row.dart';

/// Everything a box can hold, slot by slot (lunch-box ADR-0001): the starter
/// library and the family's own, each saying what is in it. Tapping one edits
/// it; putting one away keeps it out of pickers without losing the weeks it
/// was in. The add button is in the header, so it is there even while the
/// library is still being set up (`FE-08`).
class LunchLibraryScreen extends StatelessWidget {
  const LunchLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LunchBoardController>();
    final canEdit = context.watch<HouseholdView>().permissions.canEdit(
      HouseholdArea.lunch,
    );
    return NestScaffold(
      title: LunchCopy.libraryTitle,
      subtitle: LunchCopy.librarySubtitle,
      leading: backLeading(context),
      trailing: [
        if (canEdit)
          NestIconButton(
            icon: Icons.add_rounded,
            label: LunchCopy.newItemTitle,
            variant: NestIconButtonVariant.accent,
            onPressed: () => _add(context),
          ),
      ],
      body: NestAsyncView<LunchBoard>(
        state: controller.board,
        isEmpty: (board) => board.library.isEmpty,
        onRetry: controller.retry,
        emptyBuilder: (_) => const NestEmptyView(
          icon: Icons.menu_book_outlined,
          title: LunchCopy.libraryTitle,
          message: LunchCopy.libraryLoadingSeed,
        ),
        dataBuilder: (context, board) =>
            _LibraryList(library: board.library, canEdit: canEdit),
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final controller = context.read<LunchBoardController>();
    final draft = await showLunchItemSheet(context: context);
    if (draft == null) return;
    await controller.edit.addItem(draft);
  }
}

class _LibraryList extends StatelessWidget {
  const _LibraryList({required this.library, required this.canEdit});

  final List<LunchItem> library;
  final bool canEdit;

  /// Headings and items in reading order: each slot's items under its name,
  /// then everything put away.
  List<Object> get _entries {
    // By name within each slot, whatever order the listener delivers.
    final sorted = [...library]..sort((a, b) => a.nameKey.compareTo(b.nameKey));
    final active = [
      for (final item in sorted)
        if (!item.archived) item,
    ];
    final putAway = [
      for (final item in sorted)
        if (item.archived) item,
    ];
    return [
      for (final slot in LunchSlot.values)
        if (active.any((item) => item.slot == slot)) ...[
          LunchCopy.slotName(slot),
          ...active.where((item) => item.slot == slot),
        ],
      if (putAway.isNotEmpty) ...[LunchCopy.putAwayItems, ...putAway],
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Built lazily: a library grows with a family (`FE-11`).
    final entries = _entries;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      itemCount: entries.length,
      itemBuilder: (context, index) => switch (entries[index]) {
        final LunchItem item => LunchLibraryRow(
          key: ValueKey(item.id),
          item: item,
          canEdit: canEdit,
        ),
        final Object heading => Padding(
          padding: const EdgeInsets.only(top: NestSpace.lg),
          child: NestSectionHeader(title: '$heading'),
        ),
      },
    );
  }
}
