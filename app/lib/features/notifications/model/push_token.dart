import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';

part 'push_token.freezed.dart';
part 'push_token.g.dart';

/// Which kind of phone a token is for; the server only needs to know which
/// push service fronts it.
enum PushPlatform { android, ios }

/// One phone an account's pushes go to, at `users/{uid}/pushTokens/{token}`
/// (notifications ADR-0001). Keyed by the token itself, so registering the
/// same phone twice is the same write; only its own account touches it.
@freezed
abstract class PushToken with _$PushToken {
  const factory PushToken({
    @JsonKey(includeToJson: false) required String id,
    required String token,
    required PushPlatform platform,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _PushToken;

  factory PushToken.fromJson(Map<String, Object?> json) =>
      _$PushTokenFromJson(json);

  factory PushToken.of(String token, PushPlatform platform) =>
      PushToken(id: token, token: token, platform: platform);
}
