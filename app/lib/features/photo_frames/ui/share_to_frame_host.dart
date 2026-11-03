import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../model/frame_share_item.dart';
import '../state/pending_share.dart';
import 'share_to_frame_sheet.dart';

class ShareToFrameHost extends StatefulWidget {
  const ShareToFrameHost({required this.child, super.key});

  final Widget child;

  @override
  State<ShareToFrameHost> createState() => _ShareToFrameHostState();
}

class _ShareToFrameHostState extends State<ShareToFrameHost> {
  bool _isOpen = false;

  void _open(PendingShare pending) {
    _isOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final page = mounted ? pending.take() : null;
      if (page != null) {
        await showShareToFrameSheet(
          context: context,
          item: FrameSharePage(page),
        );
      }
      if (!mounted) return;
      setState(() => _isOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<PendingShare?>();
    if (pending?.page != null && !_isOpen) _open(pending!);
    return widget.child;
  }
}
