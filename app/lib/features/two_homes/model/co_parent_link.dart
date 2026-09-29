import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/firestore/server_timestamp_converter.dart';
import '../../../shared/time/calendar_date.dart';
import 'co_parent_home.dart';
import 'custody_days.dart';
import 'custody_schedule.dart';
import 'custody_side.dart';

part 'co_parent_link.freezed.dart';
part 'co_parent_link.g.dart';

/// Where a link is: waiting for the home that made the code to confirm,
/// shared, declined, or ended by either home (household ADR-0004).
enum LinkStatus { pending, active, declined, ended }

/// This household's own copy of a link with another home, at
/// `households/{id}/coParentLinks/{linkId}` (household ADR-0004). Only the
/// co-parenting Functions write it, to both homes' copies at once; it never
/// names the other household or its profile for the child.
@freezed
abstract class CoParentLink with _$CoParentLink {
  const factory CoParentLink({
    @JsonKey(includeToJson: false) required String id,
    @JsonKey(unknownEnumValue: LinkStatus.ended) required LinkStatus status,
    required CustodySide ownSide,

    /// This household's own kid profile for the child.
    required String childMemberId,

    /// The child's first name, as the home that made the code wrote it.
    required String childName,
    required CoParentHomes homes,
    required CustodySchedule schedule,

    /// Days an accepted swap moved: `YYYY-MM-DD` → side.
    @Default(<String, String>{}) Map<String, String> overrides,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    CustodySide? awaitingSide,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    CustodySide? endedBySide,
    @ServerTimestampConverter() DateTime? createdAt,
    @ServerTimestampConverter() DateTime? updatedAt,
  }) = _CoParentLink;

  const CoParentLink._();

  factory CoParentLink.fromJson(Map<String, Object?> json) =>
      _$CoParentLinkFromJson(json);

  CustodySide get otherSide => ownSide.other;

  CoParentHome homeOf(CustodySide side) =>
      side == CustodySide.a ? homes.a : homes.b;

  CoParentHome get ownHome => homeOf(ownSide);
  CoParentHome get otherHome => homeOf(otherSide);

  bool get isActive => status == LinkStatus.active;
  bool get isPending => status == LinkStatus.pending;

  /// Still open: pending or active. A declined or ended link is history.
  bool get isOpen => isActive || isPending;

  /// This home made the code and has to say whether the home that accepted
  /// it is who they expect.
  bool get awaitsOurConfirmation => isPending && awaitingSide == ownSide;

  /// The child's days from [from] to [to] — only while the link is active.
  List<CustodyDay> daysBetween(CalendarDate from, CalendarDate to) => isActive
      ? custodyDaysBetween(
          schedule: schedule,
          overrides: overrides,
          from: from,
          to: to,
        )
      : const [];

  List<CustodyDay> upcoming(CalendarDate from, {int count = 4}) => isActive
      ? upcomingHandovers(
          schedule: schedule,
          overrides: overrides,
          from: from,
          count: count,
        )
      : const [];
}
