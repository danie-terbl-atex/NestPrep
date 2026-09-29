import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/referral_overview.dart';
import '../state/referral_controller.dart';
import 'referral_body.dart';

/// *Give a month, get a month* (subscriptions ADR-0002): the household's
/// code to share, the free months it has earned, the way to enter another
/// family's code in its first week, and every referral so far. Reached from
/// the household screen, the invite step, the paywall and the plan screen —
/// for family, while referrals are switched on. All four states come from
/// the kit (`FE-08`).
class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReferralController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: ReferralCopy.title,
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
            child: NestAsyncView<ReferralOverview>(
              state: controller.overview,
              // A household with no referrals yet still has its code to
              // share: the body is the empty state, said in place.
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (_, overview) => ReferralBody(overview: overview),
            ),
          ),
        ],
      ),
    );
  }
}
