import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/member_role.dart';
import '../state/invite_step_controller.dart';
import 'invite_qr.dart';

/// Somebody just invited: their name, what they will join as, and the code —
/// written out, so it can be read aloud to a helper standing in the kitchen —
/// with its QR, the share sheet and a copy button beside it. While the code is being
/// made the row is already there, saying so.
class SentInviteRow extends StatelessWidget {
  SentInviteRow({
    required SentInvite invite,
    required VoidCallback this.onShare,
    super.key,
  }) : displayName = invite.displayName,
       role = invite.role,
       code = invite.code;

  const SentInviteRow.making({
    required this.displayName,
    required this.role,
    super.key,
  }) : code = null,
       onShare = null;

  final String displayName;
  final MemberRole role;
  final String? code;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final code = this.code;
    final onShare = this.onShare;
    return NestCard(
      variant: NestCardVariant.tinted,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: nest.text.bodyStrong),
                Text(
                  AccessCopy.roleName(role),
                  style: nest.text.caption.copyWith(
                    color: nest.colors.inkSecondary,
                  ),
                ),
                const SizedBox(height: NestSpace.xs),
                if (code == null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      AppCopy.householdMakingCode,
                      style: nest.text.body.copyWith(
                        color: nest.colors.inkSecondary,
                      ),
                    ),
                  )
                else
                  Semantics(
                    label: AccessCopy.inviteCodeFor(displayName),
                    value: code,
                    excludeSemantics: true,
                    child: Text(
                      code,
                      style: nest.text.title.copyWith(
                        color: nest.colors.accentInk,
                        letterSpacing: NestSpace.xxs,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (code == null || onShare == null)
            SizedBox.square(
              dimension: NestSize.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: NestStroke.focus,
                color: nest.colors.accent,
              ),
            )
          else ...[
            NestIconButton(
              icon: LucideIcons.qrCode,
              label: AccessCopy.inviteShowQr,
              variant: NestIconButtonVariant.plain,
              onPressed: () => showInviteQrSheet(
                context: context,
                displayName: displayName,
                code: code,
              ),
            ),
            NestIconButton(
              icon: LucideIcons.copy,
              label: AppCopy.householdCopyCode,
              variant: NestIconButtonVariant.plain,
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
            ),
            NestIconButton(
              icon: LucideIcons.share,
              label: AccessCopy.setupShareAgain,
              variant: NestIconButtonVariant.accent,
              onPressed: onShare,
            ),
          ],
        ],
      ),
    );
  }
}
