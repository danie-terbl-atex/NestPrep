import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/premium_voucher_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../state/voucher_email_controller.dart';

class VoucherEmailFlow extends StatefulWidget {
  const VoucherEmailFlow({super.key});

  @override
  State<VoucherEmailFlow> createState() => _VoucherEmailFlowState();
}

class _VoucherEmailFlowState extends State<VoucherEmailFlow> {
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<VoucherEmailController>();
    final failure = controller.failure;
    final codeWrong =
        failure is PremiumVoucherFailure &&
        failure.problem == PremiumVoucherProblem.emailCodeWrong;
    final masked = controller.emailMasked ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: switch (controller.step) {
        VoucherEmailStep.enterEmail => [
          Text(PremiumVoucherCopy.differentEmail, style: nest.text.title),
          const SizedBox(height: NestSpace.sm),
          Text(PremiumVoucherCopy.differentEmailBody, style: nest.text.body),
          const SizedBox(height: NestSpace.xl),
          NestTextField(
            key: const ValueKey('voucher-email'),
            label: PremiumVoucherCopy.emailLabel,
            hint: PremiumVoucherCopy.emailHint,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            textCapitalization: TextCapitalization.none,
            prefixIcon: LucideIcons.mail,
            errorText: controller.emailInvalid
                ? PremiumVoucherCopy.badEmail
                : null,
            onChanged: (_) => controller.clearFieldProblems(),
            onSubmitted: controller.send,
          ),
          if (failure != null) ...[
            const SizedBox(height: NestSpace.md),
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          NestButton(
            key: const ValueKey('voucher-send-code'),
            label: PremiumVoucherCopy.sendCode,
            icon: LucideIcons.send,
            isLoading: controller.isBusy,
            onPressed: () => controller.send(_email.text),
          ),
        ],
        VoucherEmailStep.enterCode => [
          Text(PremiumVoucherCopy.differentEmail, style: nest.text.title),
          const SizedBox(height: NestSpace.sm),
          Text(PremiumVoucherCopy.codeSent(masked), style: nest.text.body),
          const SizedBox(height: NestSpace.xl),
          NestTextField(
            key: const ValueKey('voucher-code'),
            label: PremiumVoucherCopy.codeLabel,
            controller: _code,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            prefixIcon: LucideIcons.mailCheck,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                VoucherEmailController.codeLength,
              ),
            ],
            errorText: controller.codeIncomplete
                ? PremiumVoucherCopy.codeIncomplete
                : codeWrong
                ? AppCopy.failure(failure)
                : null,
            onChanged: (_) => controller.clearFieldProblems(),
            onSubmitted: controller.verify,
          ),
          if (failure != null && !codeWrong) ...[
            const SizedBox(height: NestSpace.md),
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
            ),
          ],
          const SizedBox(height: NestSpace.lg),
          NestButton(
            key: const ValueKey('voucher-verify'),
            label: PremiumVoucherCopy.confirm,
            isLoading: controller.isBusy,
            onPressed: () => controller.verify(_code.text),
          ),
          const SizedBox(height: NestSpace.md),
          NestButton(
            key: const ValueKey('voucher-resend'),
            label: PremiumVoucherCopy.sendNewCode,
            variant: NestButtonVariant.outline,
            icon: LucideIcons.refreshCw,
            onPressed: controller.canResend
                ? () {
                    _code.clear();
                    controller.resend();
                  }
                : null,
          ),
          if (controller.resendIn > 0) ...[
            const SizedBox(height: NestSpace.sm),
            Text(
              PremiumVoucherCopy.newCodeIn(controller.resendIn),
              style: nest.text.caption,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: PremiumVoucherCopy.useAnotherEmail,
            variant: NestButtonVariant.ghost,
            onPressed: () {
              _code.clear();
              controller.useAnotherEmail();
            },
          ),
        ],
        VoucherEmailStep.confirmed => [
          Text(PremiumVoucherCopy.differentEmail, style: nest.text.title),
          const SizedBox(height: NestSpace.lg),
          if (controller.isLookingForPremium) ...[
            Text(PremiumVoucherCopy.lookingForPremium, style: nest.text.body),
            const SizedBox(height: NestSpace.md),
            const NestLoadingView(rows: 1),
          ] else
            NestBanner(
              message: failure == null
                  ? PremiumVoucherCopy.nothingWaitingFor(masked)
                  : AppCopy.failure(failure),
              tone: NestBannerTone.success,
            ),
        ],
      },
    );
  }
}
