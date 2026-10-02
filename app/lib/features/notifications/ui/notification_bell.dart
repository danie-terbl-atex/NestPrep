import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/notifications_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../../household/model/household_view.dart';
import '../data/notification_repository.dart';
import '../state/unread_count_controller.dart';

/// The way into a person's notifications from every tab's header, with a dot
/// while anything is unread (notifications ADR-0001). It **pushes**, like the
/// household button beside it, so back returns to the tab (`FE-17`).
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final view = context.read<HouseholdView>();
    final memberId = view.viewerMember?.id ?? '';
    final householdId = view.household.id;
    return ChangeNotifierProvider(
      create: (context) => UnreadCountController(
        repository: context.read<NotificationRepository>(),
        householdId: householdId,
        memberId: memberId,
      ),
      child: _Bell(householdId: householdId),
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<UnreadCountController>().count;
    return NestIconButton(
      icon: unread == 0 ? LucideIcons.bell : LucideIcons.bell,
      label: NotificationsCopy.bellLabel(unread),
      badge: unread > 0,
      onPressed: () => context.push(NotificationsRoute.pathFor(householdId)),
    );
  }
}
