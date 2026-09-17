import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'emulator_ping.freezed.dart';
part 'emulator_ping.g.dart';

/// One document in `diagnostics/`: proof that this build reached Firestore.
/// Foundation-only; the accounts phase removes it with the open rule that
/// allows it.
@freezed
abstract class EmulatorPing with _$EmulatorPing {
  const factory EmulatorPing({
    @JsonKey(includeToJson: false) required String id,
    required String sentFrom,
    @ServerTimestampConverter() DateTime? sentAt,
  }) = _EmulatorPing;

  factory EmulatorPing.fromJson(Map<String, Object?> json) =>
      _$EmulatorPingFromJson(json);
}
