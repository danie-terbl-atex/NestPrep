import 'package:flutter/material.dart';

import '../../../app/seeded_sign_in.dart';
import '../../../design/nest_kit.dart';

/// The one-tap shortcut into a seeded or demo account. Whether a build has one
/// at all is [SeededSignIn.forBuild]'s decision, so this widget stays a plain
/// list of choices (`FE-03`).
class SeededAccountPicker extends StatelessWidget {
  const SeededAccountPicker({
    required this.hint,
    required this.accounts,
    required this.isBusy,
    required this.onPick,
    super.key,
  });

  final String hint;
  final List<SeededAccount> accounts;
  final bool isBusy;
  final ValueChanged<SeededAccount> onPick;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          hint,
          style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NestSpace.md),
        for (final account in accounts)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: NestButton(
              label: account.label,
              variant: NestButtonVariant.outline,
              size: NestButtonSize.small,
              onPressed: isBusy ? null : () => onPick(account),
            ),
          ),
      ],
    );
  }
}
