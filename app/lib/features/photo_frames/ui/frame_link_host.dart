import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/photo_frame_route.dart';
import '../../../shared/copy/photo_frame_copy.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/household_place.dart';
import '../../household/model/household_view.dart';
import '../state/pending_frame_code.dart';

/// Takes a frame code that arrived as a link (household ADR-0012) to *Link a
/// frame* with the code already in, for whoever may link frames; anybody else
/// is told who can.
class FrameLinkHost extends StatefulWidget {
  const FrameLinkHost({required this.child, super.key});

  final Widget child;

  @override
  State<FrameLinkHost> createState() => _FrameLinkHostState();
}

class _FrameLinkHostState extends State<FrameLinkHost> {
  bool _isTaking = false;

  void _take(PendingFrameCode pending) {
    _isTaking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isTaking = false;
      if (!mounted) return;
      final code = pending.take();
      if (code == null) return;
      final view = context.read<HouseholdView>();
      final flags = context.read<FeatureFlagsController>().flags;
      if (HouseholdPlace.photoFrames.isOpenTo(view, flags)) {
        context.push(PhotoFrameRoute.linkPathFor(view.household.id, code));
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text(PhotoFrameCopy.linkNeedsFamily)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<PendingFrameCode?>();
    if (pending?.code != null && !_isTaking) _take(pending!);
    return widget.child;
  }
}
