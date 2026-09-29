import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import 'room_kind.dart';

part 'home_care_room.freezed.dart';
part 'home_care_room.g.dart';

/// A room a job can be tagged with, at `households/{id}/homeCareRooms/{roomId}`
/// (home-care ADR-0001). Its kind picks the icon; its name is what the
/// household calls it ("Lily's room").
@freezed
abstract class HomeCareRoom with _$HomeCareRoom {
  const factory HomeCareRoom({
    @JsonKey(includeToJson: false) required String id,
    required String name,
    @JsonKey(unknownEnumValue: RoomKind.other) required RoomKind kind,

    /// The member profile that added it, not the account.
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _HomeCareRoom;

  factory HomeCareRoom.fromJson(Map<String, Object?> json) =>
      _$HomeCareRoomFromJson(json);

  /// As long as the rules let a room's name be.
  static const nameLimit = 60;
}
