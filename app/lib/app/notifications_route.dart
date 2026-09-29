import 'package:go_router/go_router.dart';

import '../features/notifications/model/notification_vocabulary.dart';
import 'chore_points_route.dart';
import 'documents_route.dart';
import 'household_route.dart';
import 'household_shell.dart';
import 'nanny_hub_route.dart';

/// Where notifications live under the household shell (notifications
/// ADR-0001), and where each kind of notification lands when it is tapped.
/// The push carries a target kind and an id, never a path; this is the one
/// place the app turns one into the other, so a route renamed elsewhere cannot
/// strand a notification already on somebody's phone (`FE-17`).
abstract final class NotificationsRoute {
  static const segment = 'notifications';
  static const itemParameter = 'itemId';

  static const path = '${HouseholdRoute.path}/$segment';
  static const settingsPath = '$path/settings';
  static const itemPath = '$path/:$itemParameter';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';

  static String settingsPathFor(String householdId) =>
      '${pathFor(householdId)}/settings';

  static String itemPathFor(String householdId, String itemId) =>
      '${pathFor(householdId)}/$itemId';

  static String itemIdFrom(GoRouterState state) {
    final id = state.pathParameters[itemParameter];
    if (id == null || id.isEmpty) {
      throw StateError(
        'a notification route matched without an $itemParameter',
      );
    }
    return id;
  }

  /// Where tapping a notification lands.
  static String targetPath({
    required String householdId,
    required String inboxId,
    required NotificationTarget target,
    required String? targetId,
  }) => switch (target) {
    NotificationTarget.inboxItem => itemPathFor(householdId, inboxId),
    NotificationTarget.documents => DocumentsRoute.pathFor(householdId),
    NotificationTarget.vault when targetId != null =>
      DocumentsRoute.vaultPersonPathFor(householdId, targetId),
    NotificationTarget.vault => DocumentsRoute.vaultPathFor(householdId),
    NotificationTarget.shiftSummary when targetId != null =>
      NannyHubRoute.summaryPathFor(householdId, targetId),
    NotificationTarget.shiftSummary => NannyHubRoute.pathFor(householdId),
    NotificationTarget.stars => ChorePointsRoute.pathFor(householdId),
  };

  /// Where a digest section's link goes.
  static String sectionPath(String householdId, DigestSectionKind kind) =>
      switch (kind) {
        DigestSectionKind.events => HouseholdRoute.pathFor(
          householdId,
          HouseholdTab.week,
        ),
        DigestSectionKind.pack => HouseholdRoute.pathFor(
          householdId,
          HouseholdTab.lunch,
        ),
        DigestSectionKind.chores => HouseholdRoute.pathFor(
          householdId,
          HouseholdTab.todos,
        ),
        DigestSectionKind.documents => DocumentsRoute.pathFor(householdId),
        DigestSectionKind.shift => NannyHubRoute.pathFor(householdId),
        DigestSectionKind.approvals => ChorePointsRoute.pathFor(householdId),
      };
}
