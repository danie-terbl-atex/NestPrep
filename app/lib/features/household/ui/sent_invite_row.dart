import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/invite_step_controller.dart';

/// Somebody just invited: their name, what they will join as, and the code —
/// written out, so it can be read aloud to a helper standing in the kitchen —
/// with the share sheet and a copy button beside it.
class SentInviteRow extends StatelessWidget {
  const SentInviteRow({required this.invite, required this.onShare, super.key});

  final SentInvite invite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite.displayName, style: nest.text.bodyStrong),
                Text(
                  AccessCopy.roleName(invite.role),
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
                const SizedBox(height: NestSpace.xs),
                Semantics(
                  label: AccessCopy.inviteCodeFor(invite.displayName),
                  value: invite.code,
                  excludeSemantics: true,
                  child: Text(
                    invite.code,
                    style: nest.text.title.copyWith(
                      color: nest.colors.accentInk,
                      letterSpacing: NestSpace.xxs,
                    ),
                  ),
                ),
              ],
            ),
          ),
          NestIconButton(
            icon: LucideIcons.copy,
            label: AppCopy.householdCopyCode,
            variant: NestIconButtonVariant.plain,
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: invite.code)),
          ),
          NestIconButton(
            icon: LucideIcons.share,
            label: AccessCopy.setupShareAgain,
            variant: NestIconButtonVariant.accent,
            onPressed: onShare,
          ),
        ],
      ),
    );
  }
}
