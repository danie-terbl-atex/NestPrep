import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// The line between the address form and the providers. A hairline and a word,
/// so neither way in reads as the fallback for the other.
class SignInOrDivider extends StatelessWidget {
  const SignInOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final line = Expanded(
      child: Divider(color: nest.colors.outline, height: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NestSpace.md),
          child: Text(
            AppCopy.signInOr,
            style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
          ),
        ),
        line,
      ],
    );
  }
}
