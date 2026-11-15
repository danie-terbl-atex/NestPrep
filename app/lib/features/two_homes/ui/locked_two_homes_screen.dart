import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_area.dart';
import '../model/co_parent_link.dart';
import '../model/two_homes_access.dart';
import '../state/two_homes_controller.dart';
import 'locked_link_row.dart';

/// Two homes without Premium: locked, with the open links listed beneath so
/// an admin can still end, withdraw or turn one down — the three answers the
/// server never asks Premium for. Links still loading, or that could not be
/// read, leave the plain locked place.
class LockedTwoHomesScreen extends StatelessWidget {
  const LockedTwoHomesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<TwoHomesController>();
    final view = context.watch<HouseholdView>();
    final canEnd = TwoHomesAccess.of(view).isAdmin;
    final failure = controller.actionFailure;
    final open = controller.openLinks;
    return NestScaffold(
      title: TwoHomesCopy.title,
      leading: backLeading(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.md),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          const PremiumLockedView(feature: PremiumFeature.twoHomes),
          if (open.isNotEmpty) ...[
            const NestSectionHeader(title: TwoHomesCopy.linkedChildren),
            const SizedBox(height: NestSpace.xs),
            Text(
              TwoHomesCopy.lockedLinksBody,
              style: nest.text.caption.copyWith(
                color: nest.colors.inkSecondary,
              ),
            ),
            const SizedBox(height: NestSpace.sm),
            for (final link in open)
              Padding(
                key: ValueKey(link.id),
                padding: const EdgeInsets.only(bottom: NestSpace.sm),
                child: LockedLinkRow(
                  link: link,
                  childName:
                      view.memberById(link.childMemberId)?.displayName ??
                      link.childName,
                  canEnd: canEnd,
                  isBusy: controller.busyLinkId == link.id,
                  onEnd: () => _end(context, link),
                  onWithdraw: () => controller.end(link),
                  onDecline: () => controller.confirm(link, accept: false),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _end(BuildContext context, CoParentLink link) async {
    final controller = context.read<TwoHomesController>();
    final sure = await showNestConfirm(
      context: context,
      title: TwoHomesCopy.endQuestion(link.otherHome.name),
      message: TwoHomesCopy.endBody,
      confirmLabel: TwoHomesCopy.endConfirm,
      cancelLabel: TwoHomesCopy.endCancel,
      isDangerous: true,
    );
    if (sure ?? false) await controller.end(link);
  }
}
