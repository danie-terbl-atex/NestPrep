import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/nullable_timestamp_converter.dart';
import 'calendar_provider.dart';
import 'connection_status.dart';

part 'calendar_connection.freezed.dart';
part 'calendar_connection.g.dart';

/// A calendar a member connected, at
/// `households/{id}/calendarConnections/{connectionId}` — what the household
/// may see of it (calendar ADR-0003). The refresh token or the link itself is
/// somewhere no client can read; only a Function writes this.
@freezed
abstract class CalendarConnection with _$CalendarConnection {
  const factory CalendarConnection({
    @JsonKey(includeToJson: false) required String id,
    @JsonKey(unknownEnumValue: CalendarProvider.ics)
    required CalendarProvider provider,

    /// The member whose calendar it is; imported events are drawn in their
    /// colour.
    required String memberId,
    required String ownerUid,

    /// The account's address, or a calendar link's host.
    @Default('') String accountLabel,

    /// A status this build has never heard of reads as unreachable: something
    /// is wrong, and the next sync will say what (`BE-10`).
    @JsonKey(unknownEnumValue: ConnectionStatus.unreachable)
    @Default(ConnectionStatus.connected)
    ConnectionStatus status,
    @Default(0) int eventCount,
    @NullableTimestampConverter() DateTime? lastSyncedAt,
  }) = _CalendarConnection;

  const CalendarConnection._();

  factory CalendarConnection.fromJson(Map<String, Object?> json) =>
      _$CalendarConnectionFromJson(json);

  /// Syncing again and disconnecting are the owner's, or an admin's — the
  /// Functions enforce it; this only decides which buttons are worth showing.
  bool mayBeManagedBy({required String uid, required bool isAdmin}) =>
      isAdmin || ownerUid == uid;
}
