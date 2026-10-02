import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/home_care_room.dart';
import '../model/room_kind.dart';
import 'room_kind_look.dart';

/// What the room sheet came back with.
sealed class RoomSheetOutcome {
  const RoomSheetOutcome();
}

final class RoomSaved extends RoomSheetOutcome {
  const RoomSaved({required this.name, required this.kind});

  final String name;
  final RoomKind kind;
}

final class RoomDeleted extends RoomSheetOutcome {
  const RoomDeleted();
}

/// Adds a room, or renames one — [room] is the one being changed, and only
/// a room that exists can be deleted from here.
Future<RoomSheetOutcome?> showRoomSheet({
  required BuildContext context,
  HomeCareRoom? room,
}) => showNestSheet<RoomSheetOutcome>(
  context: context,
  title: room == null
      ? HomeCareLibraryCopy.addRoom
      : HomeCareLibraryCopy.editRoom,
  builder: (context) => _RoomBody(room: room),
);

class _RoomBody extends StatefulWidget {
  const _RoomBody({required this.room});

  final HomeCareRoom? room;

  @override
  State<_RoomBody> createState() => _RoomBodyState();
}

class _RoomBodyState extends State<_RoomBody> {
  late final _name = TextEditingController(text: widget.room?.name ?? '');
  late RoomKind _kind = widget.room?.kind ?? RoomKind.other;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final canSave = _name.text.trim().isNotEmpty;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NestTextField(
            label: HomeCareLibraryCopy.roomName,
            hint: HomeCareLibraryCopy.roomNameHint,
            controller: _name,
            autofocus: widget.room == null,
            inputFormatters: [
              LengthLimitingTextInputFormatter(HomeCareRoom.nameLimit),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NestSpace.lg),
          Text(
            HomeCareLibraryCopy.roomKind,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.sm,
            children: [
              for (final kind in RoomKind.values)
                NestChip(
                  label: HomeCareLibraryCopy.roomKindName(kind),
                  icon: kind.icon,
                  isSelected: kind == _kind,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: AppCopy.householdSave,
            onPressed: canSave
                ? () =>
                      Navigator.of(context)
                          .pop(RoomSaved(name: _name.text.trim(), kind: _kind))
                : null,
          ),
          if (widget.room != null) ...[
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: HomeCareLibraryCopy.deleteRoom,
              variant: NestButtonVariant.ghost,
              icon: LucideIcons.trash2,
              onPressed: () => Navigator.of(context).pop(const RoomDeleted()),
            ),
          ],
          const SizedBox(height: NestSpace.lg),
        ],
      ),
    );
  }
}
