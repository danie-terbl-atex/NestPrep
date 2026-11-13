import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The sign-in providers as a row of their marks, below the address form
/// (accounts ADR-0009). Apple is offered on iOS only (accounts ADR-0014).
class SignInProviders extends StatelessWidget {
  const SignInProviders({
    required this.isBusy,
    required this.onGoogle,
    required this.onApple,
    super.key,
  });

  final bool isBusy;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  static bool get offersApple => defaultTargetPlatform == TargetPlatform.iOS;

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
        if (offersApple) ...[
          const SizedBox(width: NestSpace.lg),
          NestProviderButton(
            provider: NestProvider.apple,
            label: AppCopy.signInWithApple,
            onPressed: isBusy ? null : onApple,
          ),
        ],
      ],
    );
  }
}
