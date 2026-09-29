import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/notifications_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/notifications_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/inbox_item.dart';
import '../state/inbox_item_controller.dart';
import 'digest_section_card.dart';
import 'notification_look.dart';

/// One notification, opened — a morning digest in full, section by section,
/// each with its way into the app (notifications ADR-0002). Reached from the
/// inbox and from tapping the push itself; opening it marks it read.
class InboxItemScreen extends StatelessWidget {
  const InboxItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InboxItemController>();
    final item = switch (controller.item) {
      AsyncData(:final value) => value,
      _ => null,
    };
    return NestScaffold(
      title: item?.title ?? NotificationsCopy.inboxTitle,
      subtitle: item == null ? null : _dayOf(item, context),
      leading: backLeading(context),
      body: NestAsyncView<InboxItem?>(
        state: controller.item,
        isEmpty: (value) => value == null,
        onRetry: controller.retry,
        emptyBuilder: (_) => const NestEmptyView(
          title: NotificationsCopy.emptyTitle,
          message: NotificationsCopy.digestGone,
        ),
        dataBuilder: (context, value) =>
            _Body(item: value!, householdId: controller.householdId),
      ),
    );
  }

  static String? _dayOf(InboxItem item, BuildContext context) {
    final day = item.day;
    if (day == null) return null;
    return NestDates.full(day, context.read<HouseholdClock>().today);
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.item, required this.householdId});

  final InboxItem item;
  final String householdId;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final detail = item.detail;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        NestRiseIn(
          child: NestCard(
            variant: NestCardVariant.tinted,
            child: Row(
              children: [
                NestIconTile(
                  icon: NotificationLook.categoryIcon(item.kind),
                  tint: NotificationLook.categoryTint(item.kind),
                ),
                const SizedBox(width: NestSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NotificationsCopy.categoryName(item.kind),
                        style: nest.text.label,
                      ),
                      const SizedBox(height: NestSpace.xxs),
                      Text(item.body, style: nest.text.bodyStrong),
                      if (detail != null && detail.isNotEmpty)
                        Text(detail, style: nest.text.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final (index, section) in item.sections.indexed) ...[
          const SizedBox(height: NestSpace.lg),
          NestRiseIn(
            index: index + 1,
            child: DigestSectionCard(
              key: ValueKey('digest-section-${section.kind}'),
              section: section,
              onOpen: switch (section.sectionKind) {
                final kind? => () => unawaited(
                  context.push(
                    NotificationsRoute.sectionPath(householdId, kind),
                  ),
                ),
                null => null,
              },
            ),
          ),
        ],
      ],
    );
  }
}
