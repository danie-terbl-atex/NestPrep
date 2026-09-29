import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'kid_device.freezed.dart';
part 'kid_device.g.dart';

/// One device signed in as a kid profile, at
/// `households/{id}/kidDevices/{uid}` (accounts ADR-0003). The document id is
/// the device's own Auth uid, which is what signing it out names.
///
/// Read by the household's admins only, and written by nobody on a client —
/// the kid sign-in callables are the only writers.
@freezed
abstract class KidDevice with _$KidDevice {
  const factory KidDevice({
    @JsonKey(includeToJson: false) required String id,

    /// The kid profile this device is signed in as.
    required String memberId,

    /// What the parent called it when they made the code. Empty when they
    /// did not say.
    @Default('') String label,

    /// The admin account that made the code it was paired with.
    required String pairedBy,
    @ServerTimestampConverter() DateTime? pairedAt,
  }) = _KidDevice;

  const KidDevice._();

  factory KidDevice.fromJson(Map<String, Object?> json) =>
      _$KidDeviceFromJson(json);
}
