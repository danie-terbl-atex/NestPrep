import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/byte_size.dart';
import '../model/offline_copy.dart';
import '../state/offline_copies_controller.dart';
import 'document_preview.dart';
import 'offline_badge.dart';

/// An offline copy, opened: decrypted into memory and drawn by the app, with
/// no connection needed (documents ADR-0007). It closes itself the moment the
/// lock comes back down, like a vault document does.
Future<void> showOfflineCopySheet({
  required BuildContext context,
  required OfflineCopy copy,
}) {
  final controller = context.read<OfflineCopiesController>();
  return showNestSheet<void>(
    context: context,
    title: copy.name,
    builder: (sheetContext) =>
        ChangeNotifierProvider<OfflineCopiesController>.value(
          value: controller,
          child: _OfflineCopyBody(copy: copy),
        ),
  );
}

class _OfflineCopyBody extends StatefulWidget {
  const _OfflineCopyBody({required this.copy});

  final OfflineCopy copy;

  @override
  State<_OfflineCopyBody> createState() => _OfflineCopyBodyState();
}

class _OfflineCopyBodyState extends State<_OfflineCopyBody> {
  late final OfflineCopiesController _controller = context
      .read<OfflineCopiesController>();

  @override
  void initState() {
    super.initState();
    _controller.lock.addListener(_closeWhenLocked);
  }

  @override
  void dispose() {
    _controller.lock.removeListener(_closeWhenLocked);
    super.dispose();
  }

  void _closeWhenLocked() {
    if (!_controller.lock.isUnlocked && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final copy = widget.copy;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          DocumentPreview(
            documentId: copy.key,
            height: NestSize.pagesHeight,
            load: () => _controller.openPages(copy),
          ),
          const SizedBox(height: NestSpace.md),
          Wrap(
            spacing: NestSpace.sm,
            runSpacing: NestSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const OfflineBadge(),
              Text(
                NestBytes.format(copy.sizeBytes),
                style: nest.text.caption.copyWith(
                  color: nest.colors.inkTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: OfflineCopiesCopy.remove,
            icon: Icons.delete_outline,
            variant: NestButtonVariant.outline,
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _controller.remove(copy);
              navigator.pop();
            },
          ),
        ],
      ),
    );
  }
}
