import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/async/async_state.dart';
import '../data/avatar_seen_stage_store.dart';
import '../model/avatar_base.dart';
import '../state/avatar_studio_controller.dart';

class SeenStageMarker extends StatefulWidget {
  const SeenStageMarker({required this.child, super.key});

  final Widget child;

  @override
  State<SeenStageMarker> createState() => _SeenStageMarkerState();
}

class _SeenStageMarkerState extends State<SeenStageMarker> {
  int? _marked;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvatarStudioController>();
    if (controller.studio case AsyncData(:final value)
        when value.isKid && value.preview.base is PresetBase) {
      final stage = value.stage;
      if (_marked != stage) {
        _marked = stage;
        final store = context.read<AvatarSeenStageStore?>();
        if (store != null) {
          unawaited(
            store.markSeen(controller.householdId, controller.memberId, stage),
          );
        }
      }
    }
    return widget.child;
  }
}
