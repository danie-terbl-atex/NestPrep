import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/instant_converter.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';
import 'coordinates.dart';
import 'coordinates_converter.dart';

part 'member_location.freezed.dart';
part 'member_location.g.dart';

/// Where one member said they were, at
/// `households/{id}/memberLocations/{memberId}` (live-location ADR-0001).
///
/// **The document id is the member id**, which is the whole authorisation
/// story: the rule is `isOwnMember` on the path, so nobody can write anybody
/// else's position and a profile nobody has claimed has no writer at all. It is
/// one document overwritten in place, never a trail — the household can see
/// where somebody is, never where they have been.
@freezed
abstract class MemberLocation with _$MemberLocation {
  const factory MemberLocation({
    @JsonKey(includeToJson: false) required String id,
    @CoordinatesConverter() required Coordinates point,
    required int accuracyMetres,
    @ServerTimestampConverter() DateTime? reportedAt,

    /// When this share ends. The member chose it; the rules refuse a window
    /// longer than [LiveLocationRepository.longestShare] and refuse any write
    /// once it has passed, which is what actually stops a share.
    @InstantConverter() required DateTime sharingUntil,
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
