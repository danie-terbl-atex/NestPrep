import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/room_kind.dart';

/// How a kind of room looks: its icon and its tile's tint. Never the only
/// signal — the room's name is always beside it (`FE-13`).
extension RoomKindLook on RoomKind {
  IconData get icon => switch (this) {
    RoomKind.kitchen => LucideIcons.refrigerator,
    RoomKind.lounge => LucideIcons.sofa,
    RoomKind.dining => LucideIcons.utensils,
    RoomKind.bedroom => LucideIcons.bed,
    RoomKind.kidsRoom => LucideIcons.toyBrick,
    RoomKind.bathroom => LucideIcons.bath,
    RoomKind.laundry => LucideIcons.washingMachine,
    RoomKind.office => LucideIcons.lampDesk,
    RoomKind.outside => LucideIcons.flower2,
    RoomKind.garage => LucideIcons.warehouse,
    RoomKind.other => LucideIcons.doorClosed,
  };

  NestTileTint get tint => switch (this) {
    RoomKind.kitchen || RoomKind.dining => NestTileTint.butter,
    RoomKind.bathroom || RoomKind.laundry => NestTileTint.lilac,
    RoomKind.bedroom || RoomKind.kidsRoom => NestTileTint.guava,
    RoomKind.outside || RoomKind.garage => NestTileTint.basil,
    RoomKind.lounge || RoomKind.office || RoomKind.other => NestTileTint.accent,
  };
}
