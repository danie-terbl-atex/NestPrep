import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The sign-in providers as a row of their marks, below the address form
/// (accounts ADR-0009). Google signs in; Apple is on the screen ahead of its
/// sign-in and says so when tapped, rather than doing nothing.
class SignInProviders extends StatelessWidget {
  const SignInProviders({
    required this.isBusy,
    required this.onGoogle,
    super.key,
  });

  final bool isBusy;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NestProviderButton(
          provider: NestProvider.google,
          label: AppCopy.signInWithGoogle,
          isLoading: isBusy,
          onPressed: onGoogle,
        ),
        const SizedBox(width: NestSpace.lg),
        NestProviderButton(
          provider: NestProvider.apple,
          label: AppCopy.signInWithApple,
          onPressed: isBusy ? null : () => _appleComingSoon(context),
        ),
      ],
    );
  }

  void _appleComingSoon(BuildContext context) {
    showNestSheet<void>(
      context: context,
      title: AppCopy.signInAppleComingSoonTitle,
      builder: (sheetContext) {
        final nest = NestTheme.of(sheetContext);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppCopy.signInAppleComingSoon,
              style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
            ),
            const SizedBox(height: NestSpace.xl),
            NestButton(
              key: const ValueKey('apple-coming-soon-ok'),
              label: AppCopy.signInAppleComingSoonOk,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    );
  }
}
