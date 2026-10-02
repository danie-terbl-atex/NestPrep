import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../model/lunch_item.dart';
import '../model/lunch_pantry_week.dart';
import '../state/lunch_board_controller.dart';
import '../state/lunch_pantry_controller.dart';
import 'lunch_pantry_add_sheet.dart';
import 'lunch_pantry_entry_menu.dart';
import 'lunch_pantry_missing_card.dart';
import 'lunch_pantry_row.dart';

/// The pantry (lunch-box ADR-0006): what the week still needs, then what is
/// in the house and what has run out. The add button stays at the top in
/// every state, so an empty pantry still has its way in (`FE-08`).
class LunchPantryScreen extends StatelessWidget {
  const LunchPantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<LunchPantryController>();
    final board = context.watch<LunchBoardController>().board;
    final permissions = context.watch<HouseholdView>().permissions;
    final canEdit = permissions.canEdit(HouseholdArea.lunch);
    final library = switch (board) {
      AsyncData(:final value) => value.library,
      _ => const <LunchItem>[],
    };
    final failure = pantry.actionFailure;
    return NestScaffold(
      title: LunchPantryCopy.title,
      subtitle: LunchPantryCopy.subtitle,
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: pantry.dismissActionFailure,
              ),
            ),
          if (canEdit) ...[
            NestButton(
              label: LunchPantryCopy.addToPantry,
              icon: LucideIcons.plus,
              onPressed: () => showLunchPantryAddSheet(
                context: context,
                pantry: pantry,
                library: library,
              ),
            ),
            const SizedBox(height: NestSpace.md),
          ],
          Expanded(
            child: NestAsyncView<LunchPantryWeek>(
              state: pantry.pantry,
              isEmpty: (week) => week.isEmpty && week.shortfall.isEmpty,
              onRetry: pantry.retry,
              emptyBuilder: (context) => const NestEmptyView(
                icon: LucideIcons.refrigerator,
                title: LunchPantryCopy.emptyTitle,
                message: LunchPantryCopy.emptyBody,
              ),
              dataBuilder: (context, week) => _PantryList(
                week: week,
                canEdit: canEdit,
                canAddGroceries: permissions.canEdit(HouseholdArea.groceries),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PantryList extends StatelessWidget {
  const _PantryList({
    required this.week,
    required this.canEdit,
    required this.canAddGroceries,
  });

  final LunchPantryWeek week;
  final bool canEdit;
  final bool canAddGroceries;

  @override
  Widget build(BuildContext context) {
    final inTheHouse = week.lines.where((line) => !line.entry.isUsedUp);
    final usedUp = week.lines.where((line) => line.entry.isUsedUp);
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestRiseIn(
          child: LunchPantryMissingCard(
            week: week,
            canAddGroceries: canAddGroceries,
          ),
        ),
        for (final (title, lines) in [
          (LunchPantryCopy.inTheHouse, inTheHouse),
          (LunchPantryCopy.usedUp, usedUp),
        ])
          if (lines.isNotEmpty) ...[
            const SizedBox(height: NestSpace.xl),
            NestSectionHeader(title: title),
            const SizedBox(height: NestSpace.xs),
            for (final line in lines)
              LunchPantryRow(
                key: ValueKey(line.item.id),
                line: line,
                onPortions: canEdit
                    ? (portions) => context
                          .read<LunchPantryController>()
                          .setPortions(line.item.id, portions)
                    : null,
                onMore: canEdit ? () => _more(context, line) : null,
              ),
          ],
      ],
    );
  }

  Future<void> _more(BuildContext context, LunchPantryLine line) async {
    final pantry = context.read<LunchPantryController>();
    final action = await showLunchPantryEntryMenu(
      context: context,
      name: line.item.name,
      isUsedUp: line.entry.isUsedUp,
    );
    switch (action) {
      case null:
        return;
      case LunchPantryAction.topUp:
        await pantry.addPack(line.item.id);
      case LunchPantryAction.usedUp:
        await pantry.markUsedUp(line.item.id);
      case LunchPantryAction.remove:
        await pantry.remove(line.item.id);
    }
  }
}
