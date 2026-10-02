import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../model/co_parent_link.dart';
import '../model/two_homes_access.dart';
import '../state/two_homes_controller.dart';
import 'link_card.dart';
import 'past_link_row.dart';
import 'pending_link_card.dart';

/// Two homes: this household's links with the other homes its children live
/// in (household ADR-0004). Open links first — pending ones need somebody —
/// then the ways to start one, the privacy boundary, and the history.
///
/// The ways in stay on screen whether or not there is a link, so an empty
/// household is never left looking at a message with nowhere to go
/// (`lessons/an-empty-state-that-replaces-the-view-takes-away-the-way-in`).
class TwoHomesScreen extends StatelessWidget {
  const TwoHomesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TwoHomesController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: TwoHomesCopy.title,
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<List<CoParentLink>>(
              state: controller.links,
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, _) => const _Links(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Links extends StatelessWidget {
  const _Links();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TwoHomesController>();
    final view = context.watch<HouseholdView>();
    final access = TwoHomesAccess.of(view);
    final householdId = controller.householdId;
    final open = controller.openLinks;
    final past = controller.pastLinks;
    String childNameOf(CoParentLink link) =>
        view.memberById(link.childMemberId)?.displayName ?? link.childName;

    var index = 0;
    Widget arrive(Widget child) => NestRiseIn(index: index++, child: child);

    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        if (open.isEmpty)
          arrive(
            NestCard(
              variant: NestCardVariant.tinted,
              child: Column(
                children: [
                  const NestIconTile(
                    icon: Icons.cottage_outlined,
                    tint: NestTileTint.butter,
                  ),
                  const SizedBox(height: NestSpace.md),
                  Text(
                    TwoHomesCopy.emptyTitle,
                    textAlign: TextAlign.center,
                    style: NestTheme.of(context).text.title,
                  ),
                  const SizedBox(height: NestSpace.sm),
                  Text(
                    TwoHomesCopy.emptyBody,
                    textAlign: TextAlign.center,
                    style: NestTheme.of(context).text.bodySecondary,
                  ),
                ],
              ),
            ),
          )
        else ...[
          const NestSectionHeader(title: TwoHomesCopy.linkedChildren),
          const SizedBox(height: NestSpace.sm),
          for (final link in open)
            Padding(
              key: ValueKey(link.id),
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: arrive(
                link.isPending
                    ? PendingLinkCard(
                        link: link,
                        childName: childNameOf(link),
                        canAnswer: access.isAdmin,
                        isBusy: controller.busyLinkId == link.id,
                        onAnswer: (accept) =>
                            controller.confirm(link, accept: accept),
                        onWithdraw: () => controller.end(link),
                      )
                    : LinkCard(
                        link: link,
                        childName: childNameOf(link),
                        today: controller.today,
                        onTap: () => context.push(
                          TwoHomesRoute.linkPathFor(householdId, link.id),
                        ),
                      ),
              ),
            ),
        ],
        const SizedBox(height: NestSpace.lg),
        if (access.isAdmin) ...[
          NestButton(
            label: TwoHomesCopy.linkAnotherHome,
            icon: Icons.add_home_outlined,
            onPressed: () =>
                context.push(TwoHomesRoute.setupPathFor(householdId)),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: TwoHomesCopy.haveACode,
            icon: Icons.pin_outlined,
            variant: NestButtonVariant.outline,
            onPressed: () =>
                context.push(TwoHomesRoute.joinPathFor(householdId)),
          ),
        ] else
          Text(
            TwoHomesCopy.adminStartsNote,
            textAlign: TextAlign.center,
            style: NestTheme.of(context).text.caption
                .copyWith(color: NestTheme.of(context).colors.inkTertiary),
          ),
        const SizedBox(height: NestSpace.lg),
        NestCard(
          variant: NestCardVariant.flat,
          padding: EdgeInsets.zero,
          child: NestListRow(
            leading: const NestIconTile(
              icon: Icons.shield_outlined,
              tint: NestTileTint.basil,
            ),
            title: TwoHomesSetupCopy.privacyOpen,
            subtitle: TwoHomesSetupCopy.privacyOpenBody,
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                context.push(TwoHomesRoute.privacyPathFor(householdId)),
          ),
        ),
        if (past.isNotEmpty) ...[
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: TwoHomesCopy.pastLinks),
          const SizedBox(height: NestSpace.sm),
          for (final link in past)
            PastLinkRow(
              key: ValueKey(link.id),
              link: link,
              childName: childNameOf(link),
              onTap: link.status == LinkStatus.ended
                  ? () => context.push(
                      TwoHomesRoute.linkPathFor(householdId, link.id),
                    )
                  : null,
            ),
        ],
      ],
    );
  }
}
