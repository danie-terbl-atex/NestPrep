import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import '../../../shared/firestore/server_timestamp_converter.dart';
import 'reward.dart';

part 'reward_request.freezed.dart';
part 'reward_request.g.dart';

/// Where a request for a reward stands (todos ADR-0003). Null on the model
/// while the trigger has not yet looked — the stars are being counted.
enum RequestStatus { waiting, fulfilled, declined, refused }

/// Why the trigger turned a request down.
enum RequestRefusal { notEnoughPoints, rewardGone, notAKid }

/// A child asking for a reward, at `households/{id}/rewardRequests/{id}`.
///
/// The client writes the first four fields and nothing else — the rules refuse
/// anything more. The trigger then takes the stars off and fills in the rest:
/// the status, and the reward as it was, so the child's list still says what
/// they asked for after the shelf changes.
@freezed
abstract class RewardRequest with _$RewardRequest {
  const factory RewardRequest({
    @JsonKey(includeToJson: false) required String id,
    required String rewardId,

    /// The child it is for.
    required String memberId,

    /// Who asked: the child, or a parent on the child's behalf.
    required String requestedBy,
    @ServerTimestampConverter() DateTime? requestedAt,

    // ---- written by Functions only (todos ADR-0003) ----
    @JsonKey(includeToJson: false, unknownEnumValue: RequestStatus.refused)
    RequestStatus? status,
    @JsonKey(includeToJson: false) String? title,
    @JsonKey(includeToJson: false) int? cost,
    @JsonKey(includeToJson: false, unknownEnumValue: RewardIcon.gift)
    RewardIcon? icon,
    @JsonKey(includeToJson: false, unknownEnumValue: RequestRefusal.rewardGone)
    RequestRefusal? refusal,
    @JsonKey(includeToJson: false)
    @NullableTimestampConverter()
    DateTime? settledAt,
  }) = _RewardRequest;

  const RewardRequest._();

  factory RewardRequest.fromJson(Map<String, Object?> json) =>
      _$RewardRequestFromJson(json);

  /// Written, but the trigger has not yet counted the stars.
  bool get isBeingCounted => status == null;
}
