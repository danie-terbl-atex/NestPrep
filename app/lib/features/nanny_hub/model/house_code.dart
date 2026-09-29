import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'house_code.freezed.dart';
part 'house_code.g.dart';

/// Something only somebody on shift may know — the alarm code, the gate code,
/// where the spare key is — at `households/{id}/nannySecrets/{id}`
/// (nanny-hub ADR-0006). Family reads them always; anybody else only while a
/// shift they are booked on is open, and the rules check that on every read.
@freezed
abstract class HouseCode with _$HouseCode {
  const factory HouseCode({
    @JsonKey(includeToJson: false) required String id,
    required String label,
    required String value,
    String? note,
    required String createdBy,
    @ServerTimestampConverter() DateTime? createdAt,
  }) = _HouseCode;

  factory HouseCode.fromJson(Map<String, Object?> json) =>
      _$HouseCodeFromJson(json);
}
