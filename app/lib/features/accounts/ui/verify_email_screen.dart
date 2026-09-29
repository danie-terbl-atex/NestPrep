import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/session.dart';
import '../state/session_controller.dart';

/// Where somebody waits with an account but an address nobody has proved
/// (accounts ADR-0002).
///
/// This screen is an explanation, never the enforcement: `createHousehold` and
/// `redeemInvite` refuse an unverified caller on the server, and would go on
/// refusing if this screen did not exist (`BE-01`). What it buys is that the
/// person is told why before they try, and has the two buttons that fix it.
///
/// Nothing pushes the verified claim to the app — the person proves it on a web
/// page this app never sees — so there is a button to ask again rather than a
/// listener that would never fire.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  static const path = '/confirm-email';

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _stillWaiting = false;
  bool _wasResent = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final nest = NestTheme.of(context);
    final email = switch (session.session) {
      AsyncData(value: final SignedIn signedIn) => signedIn.user.email,
      _ => '',
    };

    return NestScaffold(
      title: AppCopy.verifyEmailTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_stillWaiting) ...[
              const NestBanner(
                message: AppCopy.verifyEmailStillWaiting,
                tone: NestBannerTone.warning,
              ),
              const SizedBox(height: NestSpace.lg),
            ] else if (_wasResent) ...[
              const NestBanner(
                message: AppCopy.verifyEmailResent,
                tone: NestBannerTone.success,
              ),
              const SizedBox(height: NestSpace.lg),
            ],
            Text(
              AppCopy.verifyEmailBlurb(email),
              style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
            ),
            const SizedBox(height: NestSpace.xxl),
            NestButton(
              label: AppCopy.verifyEmailSubmit,
              isLoading: _isChecking,
              onPressed: _isChecking ? null : () => _check(session),
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.verifyEmailResend,
              variant: NestButtonVariant.outline,
              onPressed: _isChecking ? null : () => _resend(session),
            ),
            const SizedBox(height: NestSpace.xl),
            Text(
              AppCopy.verifyEmailWrongAddress,
              style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.signOut,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              onPressed: session.signOut,
            ),
          ],
        ),
      ),
    );
  }

  /// A verified address changes the session, and the router moves the screen
  /// on; an unverified one leaves them here with a line saying so.
  Future<void> _check(SessionController session) async {
    setState(() {
      _isChecking = true;
      _stillWaiting = false;
      _wasResent = false;
    });
    final verified = await session.refreshEmailVerified();
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _stillWaiting = !verified;
    });
  }

  Future<void> _resend(SessionController session) async {
    await session.resendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _wasResent = true;
      _stillWaiting = false;
    });
  }
}
