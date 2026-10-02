import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/home_care_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/routine/room_routine.dart';
import '../model/routine/routine_board.dart';
import '../state/home_care_controller.dart';
import '../state/routines_controller.dart';
import 'routine_overview.dart';
import 'routine_sheet.dart';
import 'switched_off_view.dart';

/// The room routines (home-care ADR-0004): today's progress per room, and
/// every routine by room to add, change or remove. A routine belongs to a
/// room, so a household with none is sent to add them first.
class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RoutinesController>();
    final canManage = controller.access.canManage;
    final failure = controller.actionFailure;
    final board = switch (controller.board) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final canAdd = canManage && (board?.rooms.isNotEmpty ?? false);
    return NestScaffold(
      title: HomeCareRoutineCopy.routines,
      subtitle: HomeCareRoutineCopy.routinesSubtitle,
      leading: backLeading(context),
      floatingAction: canAdd
          ? NestButton(
              label: HomeCareRoutineCopy.newRoutine,
              icon: LucideIcons.plus,
              isExpanded: false,
              onPressed: () => _edit(context, controller, null),
            )
          : null,
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
                isEmpty: (board) =>
                    board.rooms.isEmpty || board.routines.isEmpty,
                onRetry: controller.retry,
                emptyBuilder: (_) => _Empty(
                  hasRooms: board?.rooms.isNotEmpty ?? false,
                  canManage: canManage,
                  onAdd: () => _edit(context, controller, null),
                ),
                dataBuilder: (context, board) => RoutineOverview(
                  board: board,
                  onOpenToday: () => context.push(
                    HomeCareRoute.todayPathFor(controller.householdId),
                  ),
                  onEdit: canManage
                      ? (routine) => _edit(context, controller, routine)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _edit(
    BuildContext context,
    RoutinesController controller,
    RoomRoutine? routine,
  ) async {
    final board = switch (controller.board) {
      AsyncData(:final value) => value,
      _ => null,
    };
    if (board == null) return;
    final outcome = await showRoutineSheet(
      context: context,
      rooms: [...board.rooms]..sort((a, b) => a.name.compareTo(b.name)),
      helpers: context.read<HomeCareController>().helpers,
      today: controller.today,
      routine: routine,
    );
    switch (outcome) {
      case null:
        return;
      case RoutineSaved(:final draft):
        await controller.save(draft);
      case RoutineDeleted():
        if (routine == null || !context.mounted) return;
        final isSure = await showNestConfirm(
          context: context,
          title: HomeCareRoutineCopy.deleteConfirm,
          message: HomeCareRoutineCopy.deleteBody,
          confirmLabel: HomeCareRoutineCopy.deleteRoutine,
          cancelLabel: AppCopy.householdCancel,
          isDangerous: true,
        );
        if (isSure ?? false) await controller.delete(routine.id);
    }
  }
}

/// No rooms yet — the way to add them; or rooms and no routine — the way to
/// the first one. Never an empty page with no way on (`FE-08`).
class _Empty extends StatelessWidget {
  const _Empty({
    required this.hasRooms,
    required this.canManage,
    required this.onAdd,
  });

  final bool hasRooms;
  final bool canManage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final householdId = context.read<RoutinesController>().householdId;
    if (!hasRooms) {
      return NestEmptyView(
        title: HomeCareRoutineCopy.noRoomsTitle,
        message: HomeCareRoutineCopy.noRoomsBody,
        icon: LucideIcons.doorOpen,
        actionLabel: canManage ? HomeCareRoutineCopy.addRooms : null,
        onAction: canManage
            ? () => context.push(HomeCareRoute.roomsPathFor(householdId))
            : null,
      );
    }
    return NestEmptyView(
      title: HomeCareRoutineCopy.emptyTitle,
      message: canManage
          ? HomeCareRoutineCopy.emptyBody
          : HomeCareRoutineCopy.emptyHelperBody,
      icon: LucideIcons.calendarSync,
      actionLabel: canManage ? HomeCareRoutineCopy.newRoutine : null,
      onAction: canManage ? onAdd : null,
    );
  }
}
