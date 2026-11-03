import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/instant_converter.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';
import 'coordinates.dart';
import 'coordinates_converter.dart';

part 'member_location.freezed.dart';
part 'member_location.g.dart';

/// How a member is sharing: a window they chose, or always (premium,
/// live-location ADR-0003). A document with no mode is a window.
enum ShareMode { window, continuous }

/// What the phone last said about how its owner is moving.
enum DeviceMotion { still, onFoot, cycling, driving, unknown }

/// Where one member last was, at `households/{id}/memberLocations/{memberId}`
/// (live-location ADR-0004). The document id is the member id, so only that
/// member's own device can write it. Their trail lives in `locationTrails`.
@freezed
abstract class MemberLocation with _$MemberLocation {
  const factory MemberLocation({
    @JsonKey(includeToJson: false) required String id,
    @CoordinatesConverter() required Coordinates point,
    required int accuracyMetres,
    @ServerTimestampConverter() DateTime? reportedAt,

    /// When this share ends: the member's window, or the lease an always-on
    /// phone renews on every write. The rules refuse any write once it has
    /// passed, which is what actually stops a share.
    @InstantConverter() required DateTime sharingUntil,
    @Default(ShareMode.window)
    @JsonKey(unknownEnumValue: ShareMode.window)
    ShareMode mode,
    @JsonKey(includeIfNull: false) int? batteryPercent,
    @JsonKey(includeIfNull: false) bool? charging,
    @JsonKey(includeIfNull: false, unknownEnumValue: DeviceMotion.unknown)
    DeviceMotion? motion,
  }) = _MemberLocation;

  const MemberLocation._();

  factory MemberLocation.fromJson(Map<String, Object?> json) =>
      _$MemberLocationFromJson(json);

  /// Whether this member is sharing at [now].
  ///
  /// A window that has closed is not "an old position" — it is *not sharing*,
  /// and the screen draws it as nobody rather than as somewhere.
  bool isSharingAt(DateTime now) => now.isBefore(sharingUntil);

  /// How old the position is at [now], or null while the write is still on its
  /// way to the server and has no time of its own yet.
  Duration? ageAt(DateTime now) {
    final reported = reportedAt;
    return reported == null ? null : now.difference(reported);
  }
}
