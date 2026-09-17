import 'package:flutter/material.dart';

import '../../../app/emulator_accounts.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The emulator-only shortcut into a seeded user. Never built on a cloud target
/// — the caller decides that, so this widget stays a plain list of choices
/// (`FE-03`).
class SeededAccountPicker extends StatelessWidget {
  const SeededAccountPicker({
    required this.accounts,
    required this.isBusy,
    required this.onPick,
    super.key,
  });

  final List<EmulatorAccount> accounts;
  final bool isBusy;
  final ValueChanged<EmulatorAccount> onPick;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppCopy.signInEmulatorHint,
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
