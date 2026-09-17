import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../data/household_directory.dart';
import '../model/member.dart';

/// Shows a freshly made invite code so an admin can read it out or copy it. The
/// code is single-use and expires in seven days (household ADR-0002), and the
/// sheet says so rather than leaving somebody to find out.
Future<void> showInviteSheet({
  required BuildContext context,
  required Member member,
  required InviteCode invite,
}) => showNestSheet<void>(
  context: context,
  title: AppCopy.householdInviteTitle,
  builder: (sheetContext) => _InviteSheetBody(member: member, invite: invite),
);

class _InviteSheetBody extends StatefulWidget {
  const _InviteSheetBody({required this.member, required this.invite});

  final Member member;
  final InviteCode invite;

  @override
  State<_InviteSheetBody> createState() => _InviteSheetBodyState();
}

class _InviteSheetBodyState extends State<_InviteSheetBody> {
  bool _hasCopied = false;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NestListRow(
          leading: NestAvatar(
            name: widget.member.displayName,
            color: widget.member.color,
          ),
          title: widget.member.displayName,
          subtitle: AppCopy.householdUnclaimed,
        ),
        const SizedBox(height: NestSpace.xl),
        NestCard(
          variant: NestCardVariant.tinted,
          padding: const EdgeInsets.symmetric(vertical: NestSpace.xl),
          child: Text(
            widget.invite.code,
            textAlign: TextAlign.center,
            style: nest.text.display.copyWith(
              color: nest.colors.accentInk,
              letterSpacing: NestSpace.xs,
            ),
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        Text(
          AppCopy.householdInviteBody,
          textAlign: TextAlign.center,
          style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: _hasCopied
              ? AppCopy.householdCodeCopied
              : AppCopy.householdCopyCode,
          icon: _hasCopied ? Icons.check : Icons.copy_outlined,
          onPressed: _copy,
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
