import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/upper_case_formatter.dart';
import '../../household/data/invite_links.dart';
import '../../household/state/pending_invite.dart';
import '../../kid_accounts/state/kid_code_controller.dart';
import '../../kid_accounts/ui/kid_code_screen.dart';

/// The one way in for anybody holding a code (accounts ADR-0009). The two
/// codes share an alphabet and differ in length, so the length says which it
/// is: eight is a grown-up's household invite, held like a tapped invite link
/// so signing in lands on it (household ADR-0006); six is a kid sign-in code,
/// taken straight to the kid's screen and redeemed there (accounts ADR-0003).
class CodeWayInSheet extends StatefulWidget {
  const CodeWayInSheet({super.key});

  static Future<void> show(BuildContext context) => showNestSheet<void>(
    context: context,
    title: AppCopy.codeWayIn,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<PendingInvite>(),
      child: const CodeWayInSheet(),
    ),
  );

  @override
  State<CodeWayInSheet> createState() => _CodeWayInSheetState();
}

class _CodeWayInSheetState extends State<CodeWayInSheet> {
  final _code = TextEditingController();
  bool _isInvalid = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String get _typed => _code.text.trim();

  bool get _canSubmit =>
      _typed.length == InviteLinks.codeLength ||
      _typed.length == KidCodeController.codeLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestTextField(
          label: AppCopy.codeWayInLabel,
          hint: AppCopy.inviteCodeHint,
          helperText: _isInvalid ? null : AppCopy.codeWayInHelper,
          controller: _code,
          autofocus: true,
          errorText: _isInvalid ? AppCopy.codeWayInInvalid : null,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.visiblePassword,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: const [UpperCaseFormatter()],
          onChanged: (_) => setState(() => _isInvalid = false),
          onSubmitted: (_) => _canSubmit ? _submit() : null,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: AppCopy.codeWayInContinue,
          onPressed: _canSubmit ? _submit : null,
        ),
      ],
    );
  }

  void _submit() {
    final typed = _typed;
    if (typed.length == KidCodeController.codeLength) {
      final code = KidCodeController.normalise(typed);
      if (code.length != KidCodeController.codeLength) {
        setState(() => _isInvalid = true);
        return;
      }
      final router = GoRouter.of(context);
      Navigator.of(context).pop();
      router.go(KidCodeScreen.pathWithCode(code));
      return;
    }
    if (!context.read<PendingInvite>().offerCode(typed)) {
      setState(() => _isInvalid = true);
      return;
    }
    Navigator.of(context).pop();
  }
}
