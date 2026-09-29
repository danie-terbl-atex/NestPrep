import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/failure/app_failure.dart';

/// A document's pages, drawn by the app from bytes read through the
/// authenticated SDK rather than fetched from a link — so the rules apply to
/// it the way they apply to everything else, and no capability URL exists for
/// it (documents ADR-0001, ADR-0003).
///
/// A photo is one page; a PDF from a vault is as many as it has, swiped
/// through. The bytes are not in any cache, so this is a live read with all
/// four states of its own (`FE-08`) — and it is the one place in the feature
/// where "offline" looks different from "refused", and both say so.
class DocumentPreview extends StatefulWidget {
  const DocumentPreview({
    required this.documentId,
    required this.load,
    this.height = NestSize.previewHeight,
    super.key,
  });

  /// Identifies which document is on screen, so reopening the sheet on another
  /// one starts a new read rather than showing the last one's pages.
  final String documentId;

  /// Every page, as image bytes, in order.
  final Future<List<Uint8List>> Function() load;
  final double height;

  @override
  State<DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<DocumentPreview> {
  AsyncState<List<Uint8List>> _pages = const AsyncLoading();
  var _page = 0;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(DocumentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.documentId != widget.documentId) _read();
  }

  Future<void> _read() async {
    setState(() {
      _pages = const AsyncLoading();
      _page = 0;
    });
    try {
      final pages = await widget.load();
      if (mounted) setState(() => _pages = AsyncData(pages));
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _pages = AsyncFailure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SizedBox(
      height: widget.height,
      child: NestAsyncView<List<Uint8List>>(
        state: _pages,
        isEmpty: (pages) => pages.isEmpty,
        onRetry: _read,
        loadingRows: 3,
        emptyBuilder: (_) => NestSkeleton(height: widget.height),
        dataBuilder: (context, pages) => Column(
          children: [
            Expanded(
              child: PageView(
                onPageChanged: (index) => setState(() => _page = index),
                children: [
                  for (final page in pages)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(NestRadius.lg),
                      child: InteractiveViewer(
                        maxScale: 4,
                        child: Image.memory(page, fit: BoxFit.contain),
                      ),
                    ),
                ],
              ),
            ),
            if (pages.length > 1) ...[
              const SizedBox(height: NestSpace.sm),
              Text(
                VaultCopy.pageOf(_page + 1, pages.length),
                style: nest.text.caption.copyWith(
                  color: nest.colors.inkTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
