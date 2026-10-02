import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/checkers_link_status.dart';
import '../state/checkers_link_controller.dart';
import 'checkers_code_step.dart';
import 'checkers_linked_card.dart';
import 'checkers_mobile_step.dart';

/// Linking the member's own Checkers account: mobile number, SMS code,
/// linked — and unlinking (the Checkers build contract). Says plainly that
/// NestPrep is not Checkers and that the link lasts an hour.
///
/// Opened from *Add to Checkers* with [returnWhenLinked], it goes back the
/// moment the account is linked, answering `true`, so the push carries on.
class CheckersLinkScreen extends StatelessWidget {
  const CheckersLinkScreen({this.returnWhenLinked = false, super.key});

  final bool returnWhenLinked;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CheckersLinkController>();
    final failure = controller.actionFailure;
    final nest = NestTheme.of(context);
    return NestScaffold(
      title: CheckersCopy.linkTitle,
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
            child: NestAsyncView<CheckersLinkStatus>(
              state: controller.status,
              // Not linked is the first step, said in place (`FE-08`).
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, _) => ListView(
                children: [
                  Text(CheckersCopy.linkIntro, style: nest.text.body),
                  const SizedBox(height: NestSpace.sm),
                  Text(
                    CheckersCopy.linkHourNote,
                    style: nest.text.bodySecondary,
                  ),
                  const SizedBox(height: NestSpace.xl),
                  switch (controller.step) {
                    CheckersLinkStep.mobile => const CheckersMobileStep(),
                    CheckersLinkStep.code => CheckersCodeStep(
                      onLinked: () => _linked(context),
                    ),
                    CheckersLinkStep.linked => const CheckersLinkedCard(),
                  },
                  const SizedBox(height: NestSpace.xxl),
                  Text(
                    CheckersCopy.notAffiliated,
                    style: nest.text.caption.copyWith(
                      color: nest.colors.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _linked(BuildContext context) {
    if (returnWhenLinked && context.canPop()) context.pop(true);
  }
}
