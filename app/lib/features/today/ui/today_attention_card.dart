import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/notifications_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/model/attention_summary.dart';
import '../../notifications/model/notification_vocabulary.dart';
import '../../notifications/state/inbox_controller.dart';
import '../../notifications/ui/notification_look.dart';

/// How many notifications still wait on the viewer, by kind, one tap from
/// the inbox where they are opened and cleared. Nothing at all while none do.
class TodayAttentionCard extends StatelessWidget {
  const TodayAttentionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final view = context.read<HouseholdView>();
    return ChangeNotifierProvider(
      create: (context) => InboxController(
        repository: context.read<NotificationRepository>(),
        householdId: view.household.id,
        memberId: view.viewerMember?.id ?? '',
      ),
      child: const _Attention(),
    );
  }
}

class _Attention extends StatelessWidget {
  const _Attention();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InboxController>();
    final summary = switch (controller.items) {
      AsyncData(:final value) => AttentionSummary.of(value),
      _ => null,
    };
    return AnimatedSize(
      duration: NestMotion.of(context).standard,
      curve: NestMotion.standardCurve,
      alignment: Alignment.topCenter,
      child: summary == null || summary.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.xxl),
              child: _Card(
                summary: summary,
                onOpen: () => context.push(
                  NotificationsRoute.pathFor(controller.householdId),
                ),
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.summary, required this.onOpen});

  final AttentionSummary summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    final title = TodayCopy.attentionTitle(summary.total);
    final detail = [
      for (final MapEntry(:key, :value) in summary.byKind.entries)
        TodayCopy.attentionPart(key, value),
    ].join(' · ');
    return Semantics(
      button: true,
      label: TodayCopy.attentionLabel(title, detail),
      excludeSemantics: true,
      child: NestCard(
        onTap: onOpen,
        padding: const EdgeInsets.all(NestSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _KindStack(kinds: summary.byKind.keys.toList()),
                const Spacer(),
                Icon(
                  LucideIcons.arrowRight,
                  size: NestSize.iconMedium,
                  color: c.accentInk,
                ),
              ],
            ),
            const SizedBox(height: NestSpace.md),
            Text.rich(
              TextSpan(
                style: nest.text.title,
                children: [
                  TextSpan(
                    text: '${summary.total}',
                    style: TextStyle(color: c.accentInk),
                  ),
                  TextSpan(text: ' ${TodayCopy.attentionNeeds(summary.total)}'),
                ],
              ),
            ),
            const SizedBox(height: NestSpace.xs),
            Text(detail, style: nest.text.bodySecondary),
          ],
        ),
      ),
    );
  }
}

/// The kinds waiting, as their inbox tiles fanned over each other.
class _KindStack extends StatelessWidget {
  const _KindStack({required this.kinds});

  final List<NotificationCategory> kinds;

  static const _shown = 4;
  static const _tile = NestSize.avatarMedium;
  static const _ring = 2.0;
  static const _step = _tile * 0.72;

  @override
  Widget build(BuildContext context) {
    final surface = NestTheme.of(context).colors.surface;
    final shown = kinds.take(_shown).toList();
    const outer = _tile + _ring * 2;
    return SizedBox(
      width: outer + _step * (shown.length - 1),
      height: outer,
      child: Stack(
        children: [
          for (final (index, kind) in shown.indexed.toList().reversed)
            Positioned(
              left: _step * index,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(NestRadius.md + _ring),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_ring),
                  child: NestIconTile(
                    icon: NotificationLook.categoryIcon(kind),
                    tint: NotificationLook.categoryTint(kind),
                    size: _tile,
                    iconSize: NestSize.iconMedium,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
