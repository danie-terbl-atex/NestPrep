import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/lunch_board.dart';
import '../state/lunch_board_controller.dart';
import 'art/lunch_photo.dart';
import 'lunch_day_card.dart';

/// One day's box, opened from its photo: the photo settles at the detail
/// zoom, and under it the day's compartments, as editable as on the week.
/// It follows the board live, so a change made here is the week's change.
class LunchDayDetailScreen extends StatelessWidget {
  const LunchDayDetailScreen({
    required this.heroTag,
    required this.childId,
    required this.date,
    required this.canEdit,
    super.key,
  });

  final Object heroTag;
  final String childId;
  final CalendarDate date;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<LunchBoardController>().board;
    if (board is! AsyncData<LunchBoard>) return const NestLoadingView();
    final value = board.value;
    final childWeek = value.childWeek(childId);
    final day = childWeek?.days.where((day) => day.date == date).firstOrNull;
    if (childWeek == null || day == null) return const NestLoadingView();
    final name = childWeek.child.member.displayName;
    return NestScaffold(
      leading: NestIconButton(
        icon: LucideIcons.arrowLeft,
        label: LunchCopy.lunchDetailBack,
        onPressed: () => Navigator.of(context).pop(),
      ),
      eyebrow: LunchCopy.dayFor(NestDates.weekdayName(day.date), name),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: NestPhotoFrame(
              heroTag: heroTag,
              zoomed: true,
              child: LunchPhoto(box: day.box),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          LunchDayCard(
            board: value,
            childWeek: childWeek,
            day: day,
            canEdit: canEdit,
          ),
        ],
      ),
    );
  }
}
