import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/pnp_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/pnp_link_status.dart';
import '../model/pnp_sign_in_result.dart';
import '../state/pnp_link_controller.dart';
import 'pnp_linked_card.dart';
import 'pnp_login_web_view.dart';

/// Linking the member's own Pick n Pay account on Pick n Pay's own sign-in
/// page, and unlinking it (add-to-pnp ADR-0003). Says plainly that NestPrep
/// is not Pick n Pay and never sees the password.
///
/// Opened from *Add to my Pick n Pay cart* with [returnWhenLinked], it goes
/// back the moment the account is linked, answering `true`, so the push
/// carries on.
class PnpLinkScreen extends StatelessWidget {
  const PnpLinkScreen({
    required this.signInPage,
    this.returnWhenLinked = false,
    super.key,
  });

  /// The sign-in page — the real web view, or a test's stand-in.
  final PnpSignInPageBuilder signInPage;
  final bool returnWhenLinked;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PnpLinkController>();
    final page = controller.signInPage;
    if (page != null) {
      return NestScaffold(
        title: PnpCopy.signInPageTitle,
        leading: NestIconButton(
          icon: LucideIcons.x,
          label: PnpCopy.closeSignIn,
          onPressed: controller.closeSignIn,
        ),
        bodyPadding: EdgeInsets.zero,
        body: signInPage(
          page: page,
          onResult: (result) => _finish(context, controller, result),
        ),
      );
    }
    final failure = controller.actionFailure;
    return NestScaffold(
      title: PnpCopy.linkTitle,
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
            child: NestAsyncView<PnpLinkStatus>(
              state: controller.status,
              // Not linked is the first step, said in place (`FE-08`).
              isEmpty: (_) => false,
              onRetry: controller.retry,
              emptyBuilder: (_) => const SizedBox.shrink(),
              dataBuilder: (context, status) => _Body(status: status),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finish(
    BuildContext context,
    PnpLinkController controller,
    PnpSignInResult result,
  ) async {
    final linked = await controller.finishSignIn(result);
    if (linked && returnWhenLinked && context.mounted && context.canPop()) {
      context.pop(true);
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.status});

  final PnpLinkStatus status;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PnpLinkController>();
    final nest = NestTheme.of(context);
    return ListView(
      children: [
        Text(PnpCopy.linkIntro, style: nest.text.body),
        const SizedBox(height: NestSpace.sm),
        Text(PnpCopy.passwordNote, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.xl),
        if (status.isLinked)
          const PnpLinkedCard()
        else
          NestButton(
            key: const ValueKey('pnp-sign-in'),
            label: PnpCopy.signIn,
            icon: LucideIcons.logIn,
            isLoading: controller.isBusy,
            onPressed: controller.isBusy ? null : controller.startSignIn,
          ),
        const SizedBox(height: NestSpace.xxl),
        Text(
          PnpCopy.notAffiliated,
          style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
        ),
      ],
    );
  }
}
