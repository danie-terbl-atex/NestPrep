import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';

/// What the app says about itself before anybody has signed in: a sunlit
/// lunchbox that drifts in once, the lockup, and the brand line
/// (design-system ADR-0008, ADR-0010).
class SignInWelcome extends StatelessWidget {
  const SignInWelcome({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NestBrandLockup(semanticsLabel: AppCopy.appName),
        const SizedBox(height: NestSpace.xl),
        const AspectRatio(
          aspectRatio: 16 / 10,
          child: NestPhotoFrame(
            drift: true,
            semanticsLabel: AppCopy.signInPhotoLabel,
            child: Image(
              image: AssetImage(NestImagery.welcomeLunch),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: NestSpace.xxl),
        const NestRiseIn(index: 1, child: NestEyebrow(AppCopy.signInEyebrow)),
        const SizedBox(height: NestSpace.sm),
        NestRiseIn(
          index: 2,
          child: Text(
            AppCopy.brandLine,
            style: nest.text.display,
            semanticsLabel: AppCopy.brandLine,
          ),
        ),
        const SizedBox(height: NestSpace.md),
        NestRiseIn(
          index: 3,
          child: Text(AppCopy.signInTagline, style: nest.text.bodySecondary),
        ),
      ],
    );
  }
}
