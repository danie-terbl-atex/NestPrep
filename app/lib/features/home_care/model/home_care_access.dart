import 'package:flutter/foundation.dart';

import '../../household/model/access_level.dart';
import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import 'cleaning_job.dart';
import 'routine/room_routine.dart';

/// What the viewer may do in home care — the client's mirror of
/// `home_care.rules`, used only so nobody is offered what the rules would
/// refuse (`FE-04`, `BE-20`). The rules are the authority.
///
/// `edit` (family by default) assigns, reviews and keeps the library; `view`
/// reads every job; `own` — a helper's default — reads the jobs assigned to
/// her and asks for exactly those. Whoever a job is assigned to may work it.
@immutable
final class HomeCareAccess {
  const HomeCareAccess({required this.level, required this.viewerMemberId});

  factory HomeCareAccess.of(HouseholdView view) => HomeCareAccess(
    level: view.permissions.levelIn(HouseholdArea.homeCare),
    viewerMemberId: view.permissions.ownMemberId ?? view.viewerMember?.id,
  );

  final AccessLevel level;

  /// The profile `own` compares a job's helper with.
  final String? viewerMemberId;

  /// Whether home care appears in the app at all.
  bool get isVisible => level.isAnything;

  /// Assign jobs, review them, and keep the rooms and products.
  bool get canManage => level == AccessLevel.edit;

  /// Null to read every job; otherwise the one helper whose jobs to ask for.
  String? get jobScope =>
      level == AccessLevel.own ? (viewerMemberId ?? '') : null;

  bool isHelperOf(CleaningJob job) =>
      viewerMemberId != null && job.helperId == viewerMemberId;

  /// Tick its steps and hand it in.
  bool canWork(CleaningJob job) =>
      job.status.isWithHelper && (canManage || (isVisible && isHelperOf(job)));

  bool canReview(CleaningJob job) => canManage && job.status.isWaitingForReview;

  bool canChangeDetails(CleaningJob job) =>
      canManage && job.status.isWithHelper;

  /// Tick a room routine's items: family any, a helper only hers
  /// (home-care ADR-0004).
  bool canTickRoutine(RoomRoutine routine) =>
      canManage ||
      (isVisible &&
          viewerMemberId != null &&
          routine.helperId == viewerMemberId);

  /// Set a member's language: her own, or anybody's for family (home-care
  /// ADR-0006).
  bool canSetLanguageOf(String memberId) =>
      canManage || (isVisible && memberId == viewerMemberId);

  /// Who a job can be given to: anybody the household's grant lets see home
  /// care — helpers first, because that is who it is usually for.
  static List<Member> helpersIn(HouseholdView view) {
    final able = [
      for (final member in view.members)
        if (view
            .permissionsOf(member)
            .levelIn(HouseholdArea.homeCare)
            .isAnything)
          member,
    ];
    return [
      ...able.where((member) => !member.role.isFamily),
      ...able.where((member) => member.role.isFamily),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is HomeCareAccess &&
      other.level == level &&
      other.viewerMemberId == viewerMemberId;

  @override
  int get hashCode => Object.hash(level, viewerMemberId);
}
