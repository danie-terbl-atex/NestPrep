import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/upper_case_formatter.dart';
import '../../household/data/invite_links.dart';
import '../../household/state/pending_invite.dart';

/// A grown-up's invite code, typed before they have signed in. It is held
/// like a tapped invite link, so signing in or creating an account lands on
/// the invite (household ADR-0006).
class InviteCodeSheet extends StatefulWidget {
  const InviteCodeSheet({super.key});

  static Future<void> show(BuildContext context) => showNestSheet<void>(
    context: context,
    title: AccessCopy.inviteCodeWayIn,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<PendingInvite>(),
      child: const InviteCodeSheet(),
    ),
  );

  @override
  State<InviteCodeSheet> createState() => _InviteCodeSheetState();
}

class _InviteCodeSheetState extends State<InviteCodeSheet> {
  final _code = TextEditingController();
  bool _isInvalid = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _canSubmit => _code.text.trim().length == InviteLinks.codeLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: AppCopy.inviteCodeLabel,
          hint: AppCopy.inviteCodeHint,
          controller: _code,
          autofocus: true,
          errorText: _isInvalid ? AccessCopy.inviteCodeInvalid : null,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.visiblePassword,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: const [UpperCaseFormatter()],
          onChanged: (_) => setState(() => _isInvalid = false),
          onSubmitted: (_) => _canSubmit ? _submit() : null,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: AccessCopy.inviteCodeContinue,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }

  void _submit() {
    if (!context.read<PendingInvite>().offerCode(_code.text)) {
      setState(() => _isInvalid = true);
      return;
    }
    Navigator.of(context).pop();
  }
}
