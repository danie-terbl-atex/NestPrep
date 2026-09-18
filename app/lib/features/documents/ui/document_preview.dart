import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';

/// An image, read through the authenticated SDK rather than fetched from a
/// link — so the rules apply to it the way they apply to everything else, and
/// no capability URL exists for it (documents ADR-0001).
///
/// The bytes are not in any cache, so this is a live read with all four states
/// of its own (`FE-08`). It is the one place in the feature where "offline"
/// looks different from "refused", and both say so.
class DocumentPreview extends StatefulWidget {
  const DocumentPreview({
    required this.documentId,
    required this.load,
    super.key,
  });

  /// Identifies which document is on screen, so reopening the sheet on another
  /// one starts a new read rather than showing the last one's bytes.
  final String documentId;
  final Future<Uint8List> Function() load;

  @override
  State<DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<DocumentPreview> {
  AsyncState<Uint8List> _bytes = const AsyncLoading();

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
    setState(() => _bytes = const AsyncLoading());
    try {
      final bytes = await widget.load();
      if (mounted) setState(() => _bytes = AsyncData(bytes));
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _bytes = AsyncFailure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: NestSize.previewHeight,
      child: NestAsyncView<Uint8List>(
        state: _bytes,
        isEmpty: (bytes) => bytes.isEmpty,
        onRetry: _read,
        loadingRows: 3,
        emptyBuilder: (_) => const NestSkeleton(height: NestSize.previewHeight),
        dataBuilder: (context, bytes) => ClipRRect(
          borderRadius: BorderRadius.circular(NestRadius.lg),
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
