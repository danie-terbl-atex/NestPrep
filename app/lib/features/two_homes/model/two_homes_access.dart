import 'package:flutter/foundation.dart';

import '../../household/model/household_area.dart';
import '../../household/model/household_view.dart';

/// What the viewer may see and do between two homes — the client's mirror of
/// `coparent.rules` and the co-parenting callables, used only so nobody is
/// offered what the server would refuse (`FE-04`, `BE-20`, household
/// ADR-0004). The rules and the Functions are the authority.
///
/// Not premium-gated on purpose: it only works when both homes can use it.
/// If that ever changes, this is the seam.
@immutable
class TwoHomesAccess {
  const TwoHomesAccess({
    required this.canSeeSchedule,
    required this.canSeeHandovers,
    required this.canSeeRequests,
    required this.isFamily,
    required this.isAdmin,
  });

  factory TwoHomesAccess.of(HouseholdView view) {
    final permissions = view.permissions;
    final calendar = permissions.canView(HouseholdArea.calendar);
    return TwoHomesAccess(
      canSeeSchedule: calendar,
      canSeeHandovers: calendar && permissions.canView(HouseholdArea.medical),
      canSeeRequests: permissions.canEdit(HouseholdArea.calendar),
      isFamily: permissions.isFamily,
      isAdmin: view.viewerIsAdmin,
    );
  }

  /// Where the child is: the link and its schedule, read with the calendar.
  final bool canSeeSchedule;

  /// Handovers carry medicine given, so they need `medical` too.
  final bool canSeeHandovers;

  /// The adults' requests, read by whoever may change the calendar.
  final bool canSeeRequests;

  /// Family writes handovers and asks for and answers changes.
  final bool isFamily;

  /// An admin makes, accepts, confirms and ends a link.
  final bool isAdmin;

  /// Whether the household screen offers the way in at all: to the people
  /// who can do something there. Everybody else meets the link on the week.
  bool get showsWayIn => isFamily;

  (bool, bool, bool, bool, bool) get _identity =>
      (canSeeSchedule, canSeeHandovers, canSeeRequests, isFamily, isAdmin);

  @override
  bool operator ==(Object other) =>
      other is TwoHomesAccess && other._identity == _identity;

  @override
  int get hashCode => _identity.hashCode;
}
