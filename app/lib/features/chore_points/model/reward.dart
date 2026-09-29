import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'reward.freezed.dart';
part 'reward.g.dart';

/// The pictures a reward can wear — a fixed set, so a child's shelf always
/// looks like one shelf (todos ADR-0003). Stored by name; a name this build
/// does not know reads as a gift (`BE-10`).
enum RewardIcon {
  gift,
  treat,
  iceCream,
  screenTime,
  movie,
  game,
  outing,
  book,
  toy,
  lateNight,
}

/// Something a child can spend stars on, at `households/{id}/rewards/{id}`.
/// The household's, not one child's: every child sees the same shelf. Family
/// writes it (todos ADR-0003).
@freezed
abstract class Reward with _$Reward {
  const factory Reward({
    @JsonKey(includeToJson: false) required String id,
    required String title,

    /// Stars, 1 to [maxCost].
    required int cost,
    @JsonKey(unknownEnumValue: RewardIcon.gift)
    @Default(RewardIcon.gift)
    RewardIcon icon,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _Reward;

  const Reward._();

  factory Reward.fromJson(Map<String, Object?> json) => _$RewardFromJson(json);

  static const maxCost = 10000;
  static const maxTitleLength = 60;
}
