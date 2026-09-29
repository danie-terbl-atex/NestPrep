import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/room_kind.dart';

/// How a kind of room looks: its icon and its tile's tint. Never the only
/// signal — the room's name is always beside it (`FE-13`).
extension RoomKindLook on RoomKind {
  IconData get icon => switch (this) {
    RoomKind.kitchen => Icons.kitchen_outlined,
    RoomKind.lounge => Icons.weekend_outlined,
    RoomKind.dining => Icons.table_restaurant_outlined,
    RoomKind.bedroom => Icons.bed_outlined,
    RoomKind.kidsRoom => Icons.toys_outlined,
    RoomKind.bathroom => Icons.bathtub_outlined,
    RoomKind.laundry => Icons.local_laundry_service_outlined,
    RoomKind.office => Icons.desk_outlined,
    RoomKind.outside => Icons.yard_outlined,
    RoomKind.garage => Icons.garage_outlined,
    RoomKind.other => Icons.door_front_door_outlined,
  };

  NestTileTint get tint => switch (this) {
    RoomKind.kitchen || RoomKind.dining => NestTileTint.peach,
    RoomKind.bathroom || RoomKind.laundry => NestTileTint.sky,
    RoomKind.bedroom || RoomKind.kidsRoom => NestTileTint.pink,
    RoomKind.outside || RoomKind.garage => NestTileTint.mint,
    RoomKind.lounge || RoomKind.office || RoomKind.other => NestTileTint.accent,
  };
}
