import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/routine/room_day.dart';
import '../model/routine/routine_board.dart';
import '../state/helper_language_controller.dart';
import '../state/routines_controller.dart';
import 'language_bar.dart';
import 'room_day_card.dart';
import 'switched_off_view.dart';

/// Today's rooms (home-care ADR-0004): every room with a routine today, one
/// big card each, its items ticked as she goes — hers only for a helper,
/// everybody's with names for a parent. In her own language with read-aloud
/// when she has chosen one (ADR-0006).
class TodayRoomsScreen extends StatelessWidget {
  const TodayRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RoutinesController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: HomeCareRoutineCopy.today,
      subtitle: NestDates.full(controller.today, controller.today),
      leading: backLeading(context),
      body: SwitchedOffView(
        flag: FeatureFlag.homeCareRoutines,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (failure != null)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.lg),
                child: NestBanner(
                  message: AppCopy.failure(failure),
                  tone: NestBannerTone.danger,
                  actionLabel: AppCopy.back,
                  onAction: controller.dismissActionFailure,
                ),
              ),
            Expanded(
              child: NestAsyncView<RoutineBoard>(
                state: controller.board,
                isEmpty: (board) => _daysOf(board, controller).isEmpty,
                onRetry: controller.retry,
                emptyBuilder: (_) => const NestEmptyView(
                  title: HomeCareRoutineCopy.nothingTodayTitle,
                  message: HomeCareRoutineCopy.nothingTodayBody,
                  icon: Icons.wb_sunny_outlined,
                ),
                dataBuilder: (context, board) => _Rooms(
                  board: board,
                  days: _daysOf(board, controller),
                  controller: controller,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A helper's rooms today, or — for family — everybody's.
  static List<RoomDay> _daysOf(
    RoutineBoard board,
    RoutinesController controller,
  ) => board.roomsOn(
    board.today,
    helperId: controller.access.canManage
        ? null
        : controller.access.viewerMemberId,
  );
}

class _Rooms extends StatelessWidget {
  const _Rooms({
    required this.board,
    required this.days,
    required this.controller,
  });

  final RoutineBoard board;
  final List<RoomDay> days;
  final RoutinesController controller;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<HelperLanguageController>();
    final texts = [
      for (final day in days)
        for (final visit in day.visits)
          for (final item in visit.routine.items) item.text,
    ];
    language.ensure(texts);
    final access = controller.access;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (language.language.needsTranslation) ...[
          LanguageBar(texts: texts),
          const SizedBox(height: NestSpace.lg),
        ],
        if (days.every((day) => day.isDone)) ...[
          const NestRiseIn(
            child: NestBanner(
              message: HomeCareRoutineCopy.allRoomsDone,
              tone: NestBannerTone.success,
            ),
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        for (final (index, day) in days.indexed) ...[
          NestRiseIn(
            key: ValueKey(day.roomId),
            index: index.clamp(0, 6),
            child: RoomDayCard(
              day: day,
              showsHelpers: access.canManage,
              helperNameOf: (visit) =>
                  board.memberById(visit.routine.helperId)?.displayName ??
                  HomeCareRoutineCopy.helperGone,
              canTick: (visit) => access.canTickRoutine(visit.routine),
              onToggle: controller.toggle,
            ),
          ),
          const SizedBox(height: NestSpace.lg),
        ],
      ],
    );
  }
}
