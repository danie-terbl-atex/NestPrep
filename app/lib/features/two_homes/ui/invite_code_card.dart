import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/data/invite_sharer.dart';
import '../model/link_invite.dart';

/// The code for the other home, once it is made (household ADR-0004): large
/// enough to read out, with the share sheet first and copying second, and a
/// plain sentence saying that nothing is shared until both homes say yes.
class InviteCodeCard extends StatefulWidget {
  const InviteCodeCard({
    required this.invite,
    required this.shareOutcome,
    required this.onShare,
    required this.onDone,
    super.key,
  });

  final LinkInviteCode invite;
  final InviteShareOutcome? shareOutcome;
  final VoidCallback onShare;
  final VoidCallback onDone;

  @override
  State<InviteCodeCard> createState() => _InviteCodeCardState();
}

class _InviteCodeCardState extends State<InviteCodeCard> {
  bool _hasCopied = false;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(TwoHomesSetupCopy.codeTitle, style: nest.text.title),
        const SizedBox(height: NestSpace.md),
        NestCard(
          variant: NestCardVariant.tinted,
          padding: const EdgeInsets.symmetric(vertical: NestSpace.xl),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.invite.code,
              textAlign: TextAlign.center,
              style: nest.text.figure.copyWith(
                color: nest.colors.accentInk,
                letterSpacing: NestSpace.xs,
              ),
            ),
          ),
        ),
        const SizedBox(height: NestSpace.md),
        Text(
          TwoHomesSetupCopy.codeBody,
          textAlign: TextAlign.center,
          style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
        ),
        if (widget.shareOutcome == InviteShareOutcome.unavailable) ...[
          const SizedBox(height: NestSpace.md),
          const NestBanner(message: AccessCopy.inviteShareUnavailable),
        ],
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: TwoHomesSetupCopy.shareCode,
          icon: LucideIcons.share,
          onPressed: widget.onShare,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          variant: NestButtonVariant.outline,
          label: _hasCopied
              ? TwoHomesSetupCopy.codeCopied
              : TwoHomesSetupCopy.copyCode,
          icon: _hasCopied ? LucideIcons.check : LucideIcons.copy,
          onPressed: _copy,
        ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          variant: NestButtonVariant.ghost,
          label: TwoHomesSetupCopy.done,
          onPressed: widget.onDone,
        ),
      ],
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.invite.code));
    if (!mounted) return;
    setState(() => _hasCopied = true);
  }
}
