import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import 'assistant_scope.dart';
import 'assistant_via.dart';

part 'assistant_connection.freezed.dart';
part 'assistant_connection.g.dart';

/// An assistant a member connected, at
/// `households/{id}/assistantConnections/{grantId}` — the grant itself
/// (assistants ADR-0003). Only a Function writes it; deleting it is
/// disconnecting, and the next call the assistant makes is refused.
@freezed
abstract class AssistantConnection with _$AssistantConnection {
  const factory AssistantConnection({
    @JsonKey(includeToJson: false) required String id,

    /// The account that connected it, and the profile it acts as.
    required String uid,
    required String memberId,

    /// What the assistant calls itself, from its client registration.
    @Default('') String clientName,
    @Default('') String host,
    @JsonKey(unknownEnumValue: AssistantVia.assistant)
    @Default(AssistantVia.assistant)
    AssistantVia via,
    @Default(<String>[]) List<String> scopes,
    @NullableTimestampConverter() DateTime? createdAt,
    @NullableTimestampConverter() DateTime? lastUsedAt,
  }) = _AssistantConnection;

  const AssistantConnection._();

  factory AssistantConnection.fromJson(Map<String, Object?> json) =>
      _$AssistantConnectionFromJson(json);

  List<AssistantScope> get grantedScopes => AssistantScope.parse(scopes);
}
