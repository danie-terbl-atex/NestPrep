import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/document_upload_state.dart';

/// What is happening to the file somebody just chose.
///
/// An upload is the one thing here a person waits on, and it can fail after
/// they have walked away from the picker — so it says what is being added, how
/// far it has got, and offers the two things they might want: stop it, or try
/// it again (`FE-08`).
class DocumentUploadCard extends StatelessWidget {
  const DocumentUploadCard({
    required this.upload,
    required this.canRetry,
    required this.onCancel,
    required this.onRetry,
    required this.onDismiss,
    super.key,
  });

  final DocumentUploadState? upload;
  final bool canRetry;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final inFlight = upload;
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            inFlight?.fileName ?? AppCopy.documentsUploading,
            style: nest.text.bodyStrong,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: NestSpace.md),
          if (inFlight != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(NestRadius.pill),
              child: LinearProgressIndicator(
                value: inFlight.fraction,
                minHeight: NestStroke.focus * 3,
                backgroundColor: nest.colors.outline,
                color: nest.colors.accent,
                semanticsLabel: AppCopy.documentsUploading,
              ),
            ),
          const SizedBox(height: NestSpace.md),
          if (inFlight != null)
            NestButton(
              label: AppCopy.documentsStopUpload,
              variant: NestButtonVariant.outline,
              size: NestButtonSize.small,
              onPressed: onCancel,
            )
          else if (canRetry) ...[
            NestButton(
              label: AppCopy.retry,
              variant: NestButtonVariant.tonal,
              size: NestButtonSize.small,
              onPressed: onRetry,
            ),
            const SizedBox(height: NestSpace.sm),
            NestButton(
              label: AppCopy.householdCancel,
              variant: NestButtonVariant.ghost,
              size: NestButtonSize.small,
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}
