import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/state/session_controller.dart';
import '../state/consent_controller.dart';
import 'consent_summary.dart';
import 'legal_document_screen.dart';

/// The step between signing in and everything else, until this account has
/// agreed to the terms and the privacy policy this build ships — asked again
/// whenever either version rises (accounts ADR-0005).
///
/// The way out is signing out, not skipping: nothing in NestPrep works
/// without the agreement, so there is nothing behind a "later".
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  static const path = '/consent';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConsentController>();
    final failure = controller.failure;
    final isBusy = controller.isSubmitting;
    return NestScaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          const SizedBox(height: NestSpace.lg),
          NestIntro(
            eyebrow: controller.isUpdate
                ? null
                : AppCopy.onboardingStep(1, AppCopy.stepPromises),
            title: controller.isUpdate
                ? LegalCopy.consentUpdatedTitle
                : LegalCopy.consentTitle,
            body: controller.isUpdate
                ? LegalCopy.consentUpdatedIntro
                : LegalCopy.consentIntro,
          ),
          const SizedBox(height: NestSpace.lg),
          const NestRiseIn(child: ConsentSummary()),
          const SizedBox(height: NestSpace.lg),
          NestButton(
            label: LegalCopy.consentReadPrivacy,
            variant: NestButtonVariant.outline,
            icon: LucideIcons.shieldCheck,
            onPressed: () => context.push(LegalDocumentScreen.privacyPath),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: LegalCopy.consentReadTerms,
            variant: NestButtonVariant.outline,
            icon: LucideIcons.gavel,
            onPressed: () => context.push(LegalDocumentScreen.termsPath),
          ),
          const SizedBox(height: NestSpace.xl),
          NestCheckRow(
            label: LegalCopy.consentAdult,
            value: controller.isAdult,
            onChanged: isBusy
                ? null
                : (value) => controller.setAdult(value: value),
          ),
          const SizedBox(height: NestSpace.sm),
          NestCheckRow(
            label: LegalCopy.consentAgree,
            value: controller.agreesToTerms,
            onChanged: isBusy
                ? null
                : (value) => controller.setAgreesToTerms(value: value),
          ),
          if (failure != null) ...[
            const SizedBox(height: NestSpace.lg),
            NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.retry,
              onAction: controller.accept,
            ),
          ],
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: LegalCopy.consentAccept,
            icon: LucideIcons.check,
            isLoading: isBusy,
            onPressed: controller.canAccept ? controller.accept : null,
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: LegalCopy.consentSignOut,
            variant: NestButtonVariant.ghost,
            onPressed: isBusy
                ? null
                : () => context.read<SessionController>().signOut(),
          ),
        ],
      ),
    );
  }
}
