import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/woolworths_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/woolworths_link_status.dart';
import '../state/woolworths_link_controller.dart';
import 'woolworths_account_step.dart';
import 'woolworths_code_step.dart';
import 'woolworths_linked_card.dart';

/// Linking the member's own Woolworths account: email and password, a code
/// when Woolworths sends one, linked — and unlinking (add-to-woolworths
/// ADR-0001). Says plainly that NestPrep is not Woolworths and never sees
/// the password.
///
/// Opened from a cart push with [returnWhenLinked], it goes back the moment
/// the account is linked, answering `true`, so the push carries on.
class WoolworthsLinkScreen extends StatelessWidget {
  const WoolworthsLinkScreen({this.returnWhenLinked = false, super.key});

  final bool returnWhenLinked;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WoolworthsLinkController>();
    final failure = controller.actionFailure;
    final nest = NestTheme.of(context);
    return NestScaffold(
      title: WoolworthsCopy.linkTitle,
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
            child: NestAsyncView<WoolworthsLinkStatus>(
              state: controller.status,
              // Not linked is the first step, said in place (`FE-08`).
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, _) => ListView(
                children: [
                  Text(WoolworthsCopy.linkIntro, style: nest.text.body),
                  const SizedBox(height: NestSpace.sm),
                  Text(
                    WoolworthsCopy.passwordNote,
                    style: nest.text.bodySecondary,
                  ),
                  const SizedBox(height: NestSpace.xl),
                  switch (controller.step) {
                    WoolworthsLinkStep.account => WoolworthsAccountStep(
                      onLinked: () => _linked(context),
                    ),
                    WoolworthsLinkStep.code => WoolworthsCodeStep(
                      onLinked: () => _linked(context),
                    ),
                    WoolworthsLinkStep.linked => const WoolworthsLinkedCard(),
                  },
                  const SizedBox(height: NestSpace.xxl),
                  Text(
                    WoolworthsCopy.notAffiliated,
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
