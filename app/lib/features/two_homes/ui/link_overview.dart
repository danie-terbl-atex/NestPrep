import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../model/co_parent_link.dart';
import '../model/two_homes_access.dart';
import '../state/link_controller.dart';
import 'fortnight_strip.dart';
import 'handover_row.dart';
import 'home_swatch.dart';
import 'link_requests.dart';
import 'pending_link_card.dart';

/// What a loaded link shows (household ADR-0004), each part only for somebody
/// whose grant reaches it: the fortnight ahead for anybody who reads the
/// calendar, the handovers for whoever also reads `medical`, and the requests
/// for whoever may change the week.
class LinkOverview extends StatelessWidget {
  const LinkOverview({required this.link, required this.childName, super.key});

  final CoParentLink link;
  final String childName;

  static const fortnight = 14;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LinkController>();
    final access = TwoHomesAccess.of(context.watch<HouseholdView>());
    final nest = NestTheme.of(context);
    final today = controller.today;
    final days = link.daysBetween(today, today.addDays(fortnight - 1));
    final coming = link.upcoming(today);
    final householdId = controller.householdId;

    var index = 0;
    Widget arrive(Widget child) => NestRiseIn(index: index++, child: child);

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (link.isPending)
          arrive(
            PendingLinkCard(
              link: link,
              childName: childName,
              canAnswer: access.isAdmin,
              isBusy: controller.isSending,
              onAnswer: (accept) => controller.confirm(accept: accept),
              onWithdraw: controller.end,
            ),
          ),
        if (link.status == LinkStatus.ended)
          arrive(const NestBanner(message: TwoHomesCopy.endBody)),
        if (link.isActive) ...[
          arrive(
            NestCard(
              padding: const EdgeInsets.all(NestSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(TwoHomesCopy.nextTwoWeeks, style: nest.text.title),
                  const SizedBox(height: NestSpace.md),
                  FortnightStrip(
                    start: today,
                    sides: [
                      for (var offset = 0; offset < fortnight; offset++)
                        days
                            .where((day) => day.date == today.addDays(offset))
                            .firstOrNull
                            ?.side,
                    ],
                    homeOf: link.homeOf,
                  ),
                  const SizedBox(height: NestSpace.md),
                  Wrap(
                    spacing: NestSpace.lg,
                    runSpacing: NestSpace.xs,
                    children: [
                      HomeSwatch(
                        home: link.ownHome,
                        caption: TwoHomesCopy.legendThisHome.toLowerCase(),
                      ),
                      HomeSwatch(home: link.otherHome),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: TwoHomesCopy.comingHandovers),
          const SizedBox(height: NestSpace.sm),
          if (coming.isEmpty)
            Text(
              TwoHomesCopy.noComingHandovers,
              style: nest.text.bodySecondary,
            ),
          for (final day in coming)
            Padding(
              key: ValueKey('handover_${day.date.iso}'),
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: HandoverRow(
                link: link,
                childName: childName,
                day: day,
                today: today,
                note: controller.handoverOn(day.date),
                onTap: access.canSeeHandovers
                    ? () => context.push(
                        TwoHomesRoute.handoverPathFor(
                          householdId,
                          link.id,
                          day.date,
                        ),
                      )
                    : null,
              ),
            ),
        ],
        if (access.canSeeRequests && !link.isPending) ...[
          const SizedBox(height: NestSpace.xl),
          LinkRequests(link: link, childName: childName),
        ],
        if (!access.isFamily) ...[
          const SizedBox(height: NestSpace.lg),
          Text(
            TwoHomesCopy.scheduleOnly,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
        ],
        if (access.isAdmin && link.isActive) ...[
          const SizedBox(height: NestSpace.xxl),
          NestButton(
            label: TwoHomesCopy.endLink,
            variant: NestButtonVariant.ghost,
            icon: Icons.link_off,
            onPressed: controller.isSending ? null : () => _end(context),
          ),
        ],
      ],
    );
  }

  Future<void> _end(BuildContext context) async {
    final controller = context.read<LinkController>();
    final sure = await showNestConfirm(
      context: context,
      title: TwoHomesCopy.endQuestion(link.otherHome.name),
      message: TwoHomesCopy.endBody,
      confirmLabel: TwoHomesCopy.endConfirm,
      cancelLabel: TwoHomesCopy.endCancel,
      isDangerous: true,
    );
    if (sure ?? false) await controller.end();
  }
}
