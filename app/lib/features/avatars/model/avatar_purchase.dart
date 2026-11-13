import 'package:freezed_annotation/freezed_annotation.dart';

part 'avatar_purchase.freezed.dart';
part 'avatar_purchase.g.dart';

enum PurchaseStatus { owned, refused }

enum PurchaseRefusal {
  notEnoughStars,
  alreadyOwned,
  unknownAccessory,
  shopOff,
  notAKid,
}

@freezed
abstract class AvatarPurchase with _$AvatarPurchase {
  const factory AvatarPurchase({
    @JsonKey(includeToJson: false) required String id,
    required String memberId,
    required String accessoryId,
    @JsonKey(includeToJson: false, unknownEnumValue: PurchaseStatus.refused)
    PurchaseStatus? status,
    @JsonKey(
      includeToJson: false,
      unknownEnumValue: PurchaseRefusal.unknownAccessory,
    )
    PurchaseRefusal? reason,
  }) = _AvatarPurchase;

  const AvatarPurchase._();

  factory AvatarPurchase.fromJson(Map<String, Object?> json) =>
      _$AvatarPurchaseFromJson(json);

  bool get isWaiting => status == null;
}
