import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'photo_update.freezed.dart';
part 'photo_update.g.dart';

/// A photo a carer sent the parents during a shift, at
/// `households/{id}/nannyShifts/{shiftId}/photoUpdates/{id}` (nanny-hub
/// ADR-0004). It is a message, not a log line: it reaches the parents' feed
/// the moment it is written, and notifications pushes it from the same
/// document. The bytes are in Storage beside every other hub photo.
@freezed
abstract class PhotoUpdate with _$PhotoUpdate {
  const factory PhotoUpdate({
    @JsonKey(includeToJson: false) required String id,
    required String photoId,
    String? caption,
    @Default(<String>[]) List<String> childIds,
    required String byMemberId,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _PhotoUpdate;

  factory PhotoUpdate.fromJson(Map<String, Object?> json) =>
      _$PhotoUpdateFromJson(json);
}
