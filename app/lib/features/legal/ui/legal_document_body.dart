import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/legal_block.dart';
import '../model/legal_document.dart';
import 'legal_rich_text.dart';

/// A legal document laid out to be read on a phone: its date and version,
/// then every section in order. Lazy, because the privacy policy is a couple
/// of hundred blocks (`FE-11`).
class LegalDocumentBody extends StatelessWidget {
  const LegalDocumentBody({
    required this.document,
    required this.onOpenLink,
    super.key,
  });

  final LegalDocument document;
  final ValueChanged<Uri> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final blocks = document.blocks;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      itemCount: blocks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: Wrap(
              spacing: NestSpace.sm,
              runSpacing: NestSpace.sm,
              children: [
                NestTag(label: LegalCopy.updated(document.updated)),
                NestTag(label: LegalCopy.version(document.version)),
              ],
            ),
          );
        }
        return _LegalBlockView(
          block: blocks[index - 1],
          onOpenLink: onOpenLink,
          textTheme: nest.text,
        );
      },
    );
  }
}

class _LegalBlockView extends StatelessWidget {
  const _LegalBlockView({
    required this.block,
    required this.onOpenLink,
    required this.textTheme,
  });

  final LegalBlock block;
  final ValueChanged<Uri> onOpenLink;
  final NestTextStyles textTheme;

  @override
  Widget build(BuildContext context) => switch (block) {
    LegalHeading(:final level, :final spans) => Padding(
      padding: EdgeInsets.only(
        top: level == 2 ? NestSpace.xl : NestSpace.md,
        bottom: NestSpace.sm,
      ),
      child: Semantics(
        header: true,
        child: LegalRichText(
          spans: spans,
          style: level == 2 ? textTheme.title : textTheme.bodyStrong,
          onOpenLink: onOpenLink,
        ),
      ),
    ),
    LegalParagraph(:final spans) => Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.md),
      child: LegalRichText(
        spans: spans,
        style: textTheme.body,
        onOpenLink: onOpenLink,
      ),
    ),
    LegalBullets(:final items) => Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Text('•', style: textTheme.body)),
                  const SizedBox(width: NestSpace.sm),
                  Expanded(
                    child: LegalRichText(
                      spans: item,
                      style: textTheme.body,
                      onOpenLink: onOpenLink,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  };
}
