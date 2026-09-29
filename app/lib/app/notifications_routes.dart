import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/household/model/household_view.dart';
import '../features/household/model/member_role.dart';
import '../features/notifications/data/notification_directory.dart';
import '../features/notifications/data/notification_repository.dart';
import '../features/notifications/state/inbox_controller.dart';
import '../features/notifications/state/inbox_item_controller.dart';
import '../features/notifications/state/notification_settings_controller.dart';
import '../features/notifications/state/push_registrar.dart';
import '../features/notifications/state/turn_on_notifications.dart';
import '../features/notifications/ui/inbox_item_screen.dart';
import '../features/notifications/ui/inbox_screen.dart';
import '../features/notifications/ui/notification_settings_screen.dart';
import 'household_route.dart';
import 'notifications_route.dart';
import 'viewer_member.dart';

/// Notifications' routes under the household shell (notifications ADR-0001):
/// the inbox, its settings, and one notification opened. In their own file so
/// the route table gains one line. Settings is listed before the item, so
/// "settings" is never read as an item's id.
List<GoRoute> notificationsRoutes() => [
  GoRoute(
    path: NotificationsRoute.path,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => InboxController(
        repository: context.read<NotificationRepository>(),
        householdId: HouseholdRoute.idFrom(state),
        memberId: viewerMemberIdOf(context),
      ),
      child: const InboxScreen(),
    ),
  ),
  GoRoute(
    path: NotificationsRoute.settingsPath,
    builder: (context, state) {
      final view = context.read<HouseholdView>();
      return ChangeNotifierProvider(
        create: (context) => NotificationSettingsController(
          repository: context.read<NotificationRepository>(),
          directory: context.read<NotificationDirectory>(),
          registrar: context.read<PushRegistrar>(),
          owner: NotificationsOwner(
            householdId: HouseholdRoute.idFrom(state),
            memberId: viewerMemberIdOf(context),
            isFamily: view.permissions.isFamily,
          ),
          kids: [
            for (final member in view.members)
              if (member.role == MemberRole.kid) member,
          ],
        ),
        child: const NotificationSettingsScreen(),
      );
    },
  ),
  GoRoute(
    path: NotificationsRoute.itemPath,
    builder: (context, state) => ChangeNotifierProvider(
      create: (context) => InboxItemController(
        repository: context.read<NotificationRepository>(),
        householdId: HouseholdRoute.idFrom(state),
        itemId: NotificationsRoute.itemIdFrom(state),
      ),
      child: const InboxItemScreen(),
    ),
  ),
];
