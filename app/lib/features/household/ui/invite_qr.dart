import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../data/invite_links.dart';

/// The invite link as a QR, for somebody in the room to scan with their own
/// camera; it opens NestPrep on the invite (household ADR-0012).
class InviteQr extends StatelessWidget {
  const InviteQr({required this.displayName, required this.code, super.key});

  final String displayName;
  final String code;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NestQrCode(
          data: InviteLinks.linkFor(code).toString(),
          semanticLabel: AccessCopy.inviteQrFor(displayName),
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          AccessCopy.inviteScanHint,
          textAlign: TextAlign.center,
          style: nest.text.caption.copyWith(color: nest.colors.inkSecondary),
        ),
      ],
    );
  }
}

Future<void> showInviteQrSheet({
  required BuildContext context,
  required String displayName,
  required String code,
}) => showNestSheet<void>(
  context: context,
  title: AccessCopy.inviteCodeFor(displayName),
  builder: (_) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InviteQr(displayName: displayName, code: code),
        const SizedBox(height: NestSpace.lg),
        Text(
          code,
          textAlign: TextAlign.center,
          style: NestTheme.of(context).text.figure.copyWith(
            color: NestTheme.of(context).colors.accentInk,
            letterSpacing: NestSpace.xs,
          ),
        ),
      ],
    ),
  ),
);
