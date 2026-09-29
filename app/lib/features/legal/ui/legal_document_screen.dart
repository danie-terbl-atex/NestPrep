import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/legal_document.dart';
import '../model/legal_kind.dart';
import '../state/legal_document_controller.dart';
import 'legal_document_body.dart';

/// The privacy policy or the terms, as the app ships them (accounts ADR-0005).
/// Readable signed in, and during the consent step before anything else is.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key});

  static const privacyPath = '/account/privacy';
  static const termsPath = '/account/terms';

  static String pathFor(LegalKind kind) => switch (kind) {
    LegalKind.privacy => privacyPath,
    LegalKind.terms => termsPath,
  };

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LegalDocumentController>();
    return NestScaffold(
      title: switch (controller.kind) {
        LegalKind.privacy => LegalCopy.privacyTitle,
        LegalKind.terms => LegalCopy.termsTitle,
      },
      leading: backLeading(context),
      body: NestAsyncView<LegalDocument>(
        state: controller.document,
        isEmpty: (document) => document.blocks.isEmpty,
        onRetry: controller.retry,
        loadingRows: 6,
        // A shipped document with nothing in it is our bug; the error view
        // is the honest thing to show, with the retry that reloads it.
        emptyBuilder: (_) => NestErrorView(
          message: AppCopy.failure(const NotFoundFailure()),
          retryLabel: AppCopy.retry,
          onRetry: controller.retry,
        ),
        dataBuilder: (context, document) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.linkWouldNotOpen) ...[
              const NestBanner(
                message: LegalCopy.linkWouldNotOpen,
                tone: NestBannerTone.warning,
              ),
              const SizedBox(height: NestSpace.md),
            ],
            Expanded(
              child: LegalDocumentBody(
                document: document,
                onOpenLink: controller.openLink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
