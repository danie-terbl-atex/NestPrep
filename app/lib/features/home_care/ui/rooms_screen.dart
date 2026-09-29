import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/home_care_board.dart';
import '../model/home_care_room.dart';
import '../state/home_care_controller.dart';
import 'room_kind_look.dart';
import 'room_sheet.dart';

/// The rooms of the home, each with how many jobs are open in it. A parent
/// adds, renames and removes them; everybody else reads them.
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeCareController>();
    final canManage = controller.access.canManage;
    final failure = controller.actionFailure;
    return NestScaffold(
      title: HomeCareLibraryCopy.rooms,
      leading: backLeading(context),
      trailing: [
        if (canManage)
          NestIconButton(
            icon: Icons.add,
            label: HomeCareLibraryCopy.addRoom,
            onPressed: () => _edit(context, controller, null),
          ),
      ],
      body: Column(
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
            child: NestAsyncView<HomeCareBoard>(
              state: controller.board,
              isEmpty: (board) => board.rooms.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => NestEmptyView(
                title: HomeCareLibraryCopy.roomsEmptyTitle,
                message: canManage
                    ? HomeCareLibraryCopy.roomsEmptyBody
                    : HomeCareLibraryCopy.roomsEmptyHelperBody,
                icon: Icons.meeting_room_outlined,
                actionLabel: canManage
                    ? HomeCareLibraryCopy.addUsualRooms
                    : null,
                onAction: canManage
                    ? () => controller.library.addRooms(
                        HomeCareLibraryCopy.usualRooms,
                      )
                    : null,
              ),
              dataBuilder: (context, board) => ListView.separated(
                itemCount: board.rooms.length,
                padding: const EdgeInsets.only(bottom: NestSpace.huge),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: NestSpace.sm),
                itemBuilder: (context, index) {
                  final room = board.roomsByName[index];
                  return NestCard(
                    variant: NestCardVariant.flat,
                    padding: EdgeInsets.zero,
                    child: NestListRow(
                      title: room.name,
                      subtitle: HomeCareLibraryCopy.openJobs(
                        board.openJobsIn(room.id),
                      ),
                      leading: NestIconTile(
                        icon: room.kind.icon,
                        tint: room.kind.tint,
                        size: NestSize.avatarMedium,
                        iconSize: NestSize.iconMedium,
                      ),
                      trailing: canManage
                          ? const Icon(Icons.edit_outlined)
                          : null,
                      onTap: canManage
                          ? () => _edit(context, controller, room)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _edit(
    BuildContext context,
    HomeCareController controller,
    HomeCareRoom? room,
  ) async {
    final outcome = await showRoomSheet(context: context, room: room);
    switch (outcome) {
      case null:
        return;
      case RoomSaved(:final name, :final kind):
        await controller.library.saveRoom(
          roomId: room?.id,
          name: name,
          kind: kind,
        );
      case RoomDeleted():
        if (room == null || !context.mounted) return;
        final isSure = await showNestConfirm(
          context: context,
          title: HomeCareLibraryCopy.deleteRoomConfirm,
          message: HomeCareLibraryCopy.deleteRoomBody,
          confirmLabel: HomeCareLibraryCopy.deleteRoom,
          cancelLabel: AppCopy.householdCancel,
          isDangerous: true,
        );
        if (isSure ?? false) await controller.library.deleteRoom(room.id);
    }
  }
}
