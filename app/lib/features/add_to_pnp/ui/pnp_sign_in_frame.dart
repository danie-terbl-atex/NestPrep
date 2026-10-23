import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/pnp_copy.dart';

/// Where Pick n Pay's sign-in page stands while it is shown.
enum PnpSignInPhase { loading, ready, failed }

/// The frame around Pick n Pay's sign-in page (`FE-08`, `FE-09`): the page
/// holds its place while it loads, a page that cannot be reached says so
/// in words with a retry, and a link the app will not follow — signing up,
/// a forgotten password — says where to do it instead of doing nothing.
class PnpSignInFrame extends StatelessWidget {
  const PnpSignInFrame({
    required this.phase,
    required this.isRefusedNoticeShown,
    required this.onRetry,
    required this.onDismissNotice,
    required this.page,
    super.key,
  });

  final PnpSignInPhase phase;
  final bool isRefusedNoticeShown;
  final VoidCallback onRetry;
  final VoidCallback onDismissNotice;

  /// The page itself; kept in the tree while it loads, so it can paint.
  final Widget page;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRefusedNoticeShown)
          // At most half the height, scrolling past it at large text, so the
          // page under it never disappears (`FE-13`).
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight / 2),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(NestSpace.lg),
              child: NestBanner(
                key: const ValueKey('pnp-sign-in-elsewhere'),
                message: PnpCopy.signInPageElsewhere,
                tone: NestBannerTone.warning,
                actionLabel: PnpCopy.signInPageNoticeDismiss,
                onAction: onDismissNotice,
              ),
            ),
          ),
        Expanded(
          child: switch (phase) {
            PnpSignInPhase.failed => Padding(
              padding: const EdgeInsets.all(NestSpace.lg),
              child: NestErrorView(
                key: const ValueKey('pnp-sign-in-failed'),
                title: PnpCopy.signInPageFailedTitle,
                message: PnpCopy.signInPageFailed,
                retryLabel: PnpCopy.signInPageRetry,
                onRetry: onRetry,
              ),
            ),
            PnpSignInPhase.loading => Stack(
              children: [
                Positioned.fill(child: page),
                Positioned.fill(
                  child: ColoredBox(
                    key: const ValueKey('pnp-sign-in-loading'),
                    color: NestTheme.of(context).colors.canvas,
                    child: const Padding(
                      padding: EdgeInsets.all(NestSpace.lg),
                      child: NestLoadingView(rows: 3),
                    ),
                  ),
                ),
              ],
            ),
            PnpSignInPhase.ready => page,
          },
        ),
      ],
    ),
  );
}
