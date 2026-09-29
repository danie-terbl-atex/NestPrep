import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'guide_spot.freezed.dart';
part 'guide_spot.g.dart';

/// One place in the house guide — "Spare nappies: top shelf of the linen
/// cupboard" — with a photo of it, at `households/{id}/nannyGuide/{id}`. The
/// photo's bytes are in Storage under the same household (nanny-hub
/// ADR-0003).
@freezed
abstract class GuideSpot with _$GuideSpot {
  const factory GuideSpot({
    @JsonKey(includeToJson: false) required String id,
    required String title,
    String? note,
    String? photoId,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _GuideSpot;

  factory GuideSpot.fromJson(Map<String, Object?> json) =>
      _$GuideSpotFromJson(json);
}
