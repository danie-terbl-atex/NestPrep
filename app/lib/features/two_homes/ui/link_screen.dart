import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/two_homes_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../model/co_parent_link.dart';
import '../state/link_controller.dart';
import 'link_overview.dart';

/// One link between two homes (household ADR-0004): the fortnight ahead, the
/// coming handovers, what each home has asked the other, and the way to end
/// it. The frame is here; what a loaded link shows is `LinkOverview`.
class LinkScreen extends StatelessWidget {
  const LinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LinkController>();
    final failure = controller.actionFailure;
    final view = context.watch<HouseholdView>();
    String childNameOf(CoParentLink link) =>
        view.memberById(link.childMemberId)?.displayName ?? link.childName;
    final loaded = switch (controller.link) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return NestScaffold(
      title: loaded == null ? TwoHomesCopy.title : childNameOf(loaded),
      subtitle: loaded == null
          ? null
          : TwoHomesCopy.homesTogether(
              loaded.ownHome.name,
              loaded.otherHome.name,
            ),
      leading: backLeading(context),
      trailing: [
        NestIconButton(
          icon: Icons.shield_outlined,
          label: TwoHomesSetupCopy.privacyOpen,
          variant: NestIconButtonVariant.plain,
          onPressed: () => context.push(
            TwoHomesRoute.privacyPathFor(controller.householdId),
          ),
        ),
      ],
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
            child: NestAsyncView<CoParentLink?>(
              state: controller.link,
              isEmpty: (link) => link == null,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                icon: Icons.link_off,
                title: TwoHomesCopy.title,
                message: TwoHomesCopy.linkGone,
              ),
              dataBuilder: (context, link) => link == null
                  ? const SizedBox.shrink()
                  : LinkOverview(link: link, childName: childNameOf(link)),
            ),
          ),
        ],
      ),
    );
  }
}
