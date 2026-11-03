import 'package:freezed_annotation/freezed_annotation.dart';

import 'grant_source.dart';

part 'grant_days_waiting.freezed.dart';
part 'grant_days_waiting.g.dart';

@freezed
abstract class GrantDaysWaiting with _$GrantDaysWaiting {
  const factory GrantDaysWaiting({
    @Default(0) int referral,
    @Default(0) int frame,
    @Default(0) int code,
  }) = _GrantDaysWaiting;

  const GrantDaysWaiting._();

  factory GrantDaysWaiting.fromJson(Map<String, Object?> json) =>
      _$GrantDaysWaitingFromJson(json);

  int of(GrantSource source) => switch (source) {
    GrantSource.referral => referral,
    GrantSource.frame => frame,
    GrantSource.code => code,
  };

  int get total => referral + frame + code;
}
