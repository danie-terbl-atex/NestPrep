import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';

/// The household's code, large enough to read out, with the share sheet first
/// and a copy button second (subscriptions ADR-0002) — the same order an
/// invite leaves in. While the server is making the code the card holds its
/// place; if it could not, the card says so and offers to try again.
class ReferralCodeCard extends StatefulWidget {
  const ReferralCodeCard({
    required this.code,
    required this.isMakingCode,
    required this.codeFailure,
    required this.onShare,
    required this.onRetry,
    super.key,
  });

  final String? code;
  final bool isMakingCode;
  final AppFailure? codeFailure;
  final VoidCallback onShare;
  final VoidCallback onRetry;

  @override
  State<ReferralCodeCard> createState() => _ReferralCodeCardState();
}

class _ReferralCodeCardState extends State<ReferralCodeCard> {
  bool _hasCopied = false;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final code = widget.code;
    final failure = widget.codeFailure;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(ReferralCopy.yourCode, style: nest.text.title),
          const SizedBox(height: NestSpace.md),
          if (code != null)
            NestCard(
              variant: NestCardVariant.tinted,
              padding: const EdgeInsets.symmetric(vertical: NestSpace.xl),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  code,
                  textAlign: TextAlign.center,
                  style: nest.text.figure.copyWith(
                    color: nest.colors.accentInk,
                    letterSpacing: NestSpace.xs,
                  ),
                ),
              ),
            )
          else if (failure != null)
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.retry,
              onAction: widget.onRetry,
            )
          else
            Semantics(
              label: ReferralCopy.preparingCode,
              child: const NestSkeleton(height: NestSize.controlHuge),
            ),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: ReferralCopy.share,
            icon: LucideIcons.share,
            onPressed: code == null ? null : widget.onShare,
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            variant: NestButtonVariant.outline,
            label: _hasCopied ? ReferralCopy.copied : ReferralCopy.copy,
            icon: _hasCopied ? LucideIcons.check : LucideIcons.copy,
            onPressed: code == null ? null : () => _copy(code),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _hasCopied = true);
  }
}
