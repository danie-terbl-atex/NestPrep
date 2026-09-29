import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/rename_sheet.dart';
import '../../family_profiles/ui/sheet_outcome.dart';
import '../model/lunch_board.dart';
import '../model/lunch_day.dart';
import '../model/lunch_feedback.dart';
import '../model/lunch_slot.dart';
import '../state/lunch_board_controller.dart';
import 'lunch_day_menu.dart';
import 'lunch_favourites_sheet.dart';
import 'lunch_feedback_sheet.dart';
import 'lunch_picker_sheet.dart';

/// The conversations a day card starts — a sheet asked, an answer handed to
/// the controller — kept out of the card so it stays about how a day looks
/// (`FE-16`). Each reads the controller from the context it is given.
abstract final class LunchFlows {
  static String _dayName(LunchDay day) => NestDates.weekdayName(day.date);

  /// The one-tap swap of one slot.
  static Future<void> pickSlot(
    BuildContext context, {
    required LunchBoard board,
    required LunchChildWeek childWeek,
    required LunchDay day,
    required LunchSlot slot,
  }) async {
    final controller = context.read<LunchBoardController>();
    final choice = await showLunchPickerSheet(
      context: context,
      slot: slot,
      dayName: _dayName(day),
      childName: childWeek.child.member.displayName,
      ranked: childWeek.rank(slot, board.library),
      current: day.box[slot],
    );
    final childId = childWeek.childId;
    final weekday = day.date.weekday;
    switch (choice) {
      case null:
        return;
      case LunchItemChosen(:final item):
        await controller.edit.pick(
          childId: childId,
          isoWeekday: weekday,
          item: item,
        );
      case LunchItemAdded(:final draft):
        await controller.edit.addAndPick(
          childId: childId,
          isoWeekday: weekday,
          draft: draft,
        );
      case LunchSlotCleared():
        await controller.edit.clear(
          childId: childId,
          isoWeekday: weekday,
          slot: slot,
        );
    }
  }

  static Future<void> dayMenu(
    BuildContext context, {
    required LunchChildWeek childWeek,
    required LunchDay day,
  }) async {
    final action = await showLunchDayMenu(
      context: context,
      dayName: _dayName(day),
      hasBox: !day.box.isEmpty,
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case LunchDayAction.saveFavourite:
        await _saveFavourite(context, childWeek: childWeek, day: day);
      case LunchDayAction.packFavourite:
        await packFavourite(context, childWeek: childWeek, day: day);
      case LunchDayAction.clear:
        await context.read<LunchBoardController>().edit.clearDay(
          childId: childWeek.childId,
          isoWeekday: day.date.weekday,
        );
    }
  }

  static Future<void> _saveFavourite(
    BuildContext context, {
    required LunchChildWeek childWeek,
    required LunchDay day,
  }) async {
    final controller = context.read<LunchBoardController>();
    final name = await showRenameSheet(
      context: context,
      title: LunchCopy.saveAsFavourite,
      label: LunchCopy.favouriteName,
      initial: '',
    );
    if (name == null) return;
    await controller.edit.saveFavourite(
      childId: childWeek.childId,
      name: name,
      box: day.box,
    );
  }

  static Future<void> packFavourite(
    BuildContext context, {
    required LunchChildWeek childWeek,
    required LunchDay day,
  }) async {
    final controller = context.read<LunchBoardController>();
    final favourite = await showLunchFavouritesSheet(
      context: context,
      childWeek: childWeek,
      onRemove: (favourite) => controller.edit.deleteFavourite(favourite.id),
    );
    if (favourite == null) return;
    await controller.edit.packFavourite(
      childId: childWeek.childId,
      isoWeekday: day.date.weekday,
      favourite: favourite,
    );
  }

  static Future<void> markBox(
    BuildContext context, {
    required LunchChildWeek childWeek,
    required LunchDay day,
    required LunchVerdict verdict,
  }) => context.read<LunchBoardController>().edit.markEaten(
    childId: childWeek.childId,
    isoWeekday: day.date.weekday,
    box: verdict,
  );

  static Future<void> markItems(
    BuildContext context, {
    required LunchChildWeek childWeek,
    required LunchDay day,
  }) async {
    final controller = context.read<LunchBoardController>();
    final outcome = await showLunchFeedbackSheet(
      context: context,
      box: day.box,
      existing: day.feedback,
    );
    final weekday = day.date.weekday;
    switch (outcome) {
      case null:
        return;
      case SheetSaved(value: final marks):
        await controller.edit.markEaten(
          childId: childWeek.childId,
          isoWeekday: weekday,
          box: marks.box,
          items: marks.items,
        );
      case SheetRemoved():
        await controller.edit.unmarkEaten(
          childId: childWeek.childId,
          isoWeekday: weekday,
        );
    }
  }
}
