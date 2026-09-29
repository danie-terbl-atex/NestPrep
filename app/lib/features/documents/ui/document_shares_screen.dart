import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../model/document_share.dart';
import '../state/document_shares_controller.dart';
import 'document_share_row.dart';

/// Every link that still works, soonest to end first, and a way to stop each
/// one (documents ADR-0006). The family sees the household's; anybody else
/// the ones they made.
class DocumentSharesScreen extends StatelessWidget {
  const DocumentSharesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentSharesController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: ShareLinkCopy.listTitle,
      leading: backLeading(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ShareLinkCopy.listBody,
            style: NestTheme.of(context).text.bodySecondary,
          ),
          const SizedBox(height: NestSpace.lg),
          if (failure != null) ...[
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: controller.dismissActionFailure,
            ),
            const SizedBox(height: NestSpace.lg),
          ],
          Expanded(
            child: NestAsyncView<List<DocumentShare>>(
              state: controller.shares,
              isEmpty: (shares) => shares.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: ShareLinkCopy.emptyTitle,
                message: ShareLinkCopy.emptyBody,
                icon: Icons.link_off,
              ),
              dataBuilder: (context, shares) => _ShareList(shares: shares),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareList extends StatelessWidget {
  const _ShareList({required this.shares});

  final List<DocumentShare> shares;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentSharesController>();
    final clock = context.read<HouseholdClock>();
    final view = context.read<HouseholdView>();
    String moment(DateTime at) =>
        NestDates.moment(clock.dateOf(at), clock.today, clock.minutesOfDay(at));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      itemCount: shares.length,
      itemBuilder: (context, index) {
        final share = shares[index];
        final lastOpened = share.lastOpenedAt;
        final createdBy = share.createdBy;
        final creator = createdBy == null
            ? null
            : view.memberById(createdBy)?.displayName;
        return Padding(
          key: ValueKey(share.id),
          padding: const EdgeInsets.only(bottom: NestSpace.sm),
          child: NestRiseIn(
            index: index,
            child: DocumentShareRow(
              documentName: share.documentName,
              endsLabel: share.isUntilShiftEnds
                  ? ShareLinkCopy.endsWithShift
                  : ShareLinkCopy.endsAt(moment(share.expiresAt)),
              openedLabel: [
                ShareLinkCopy.opened(share.openCount),
                if (lastOpened != null)
                  ShareLinkCopy.lastOpened(moment(lastOpened)),
              ].join(' · '),
              hasPin: share.hasPin,
              isFromVault: share.isFromVault,
              isStopping: controller.isStopping(share.id),
              sharedBy: controller.isFamily && creator != null
                  ? ShareLinkCopy.madeBy(creator)
                  : null,
              onStop: () => _stop(context, share),
            ),
          ),
        );
      },
    );
  }

  Future<void> _stop(BuildContext context, DocumentShare share) async {
    final controller = context.read<DocumentSharesController>();
    final confirmed = await showNestConfirm(
      context: context,
      title: ShareLinkCopy.stopTitle,
      message: ShareLinkCopy.stopBody,
      confirmLabel: ShareLinkCopy.stop,
      cancelLabel: AppCopy.householdCancel,
      isDangerous: true,
    );
    if (confirmed == true) await controller.stop(share);
  }
}
