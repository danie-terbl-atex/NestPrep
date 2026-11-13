import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../../household/model/member.dart';
import '../data/avatar_seen_stage_store.dart';
import '../model/avatar_base.dart';
import '../model/avatar_stage.dart';
import 'hatch_celebration.dart';

class HatchWatcher extends StatefulWidget {
  const HatchWatcher({
    required this.householdId,
    required this.kid,
    required this.child,
    super.key,
  });

  final String householdId;
  final Member? kid;
  final Widget child;

  @override
  State<HatchWatcher> createState() => _HatchWatcherState();
}

class _HatchWatcherState extends State<HatchWatcher> {
  String? _checked;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _check();
  }

  @override
  void didUpdateWidget(HatchWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _check();
  }

  void _check() {
    final kid = widget.kid;
    final look = kid?.look;
    final isOn =
        context.read<FeatureFlagsController?>()?.isOn(FeatureFlag.avatars) ??
        false;
    final store = context.read<AvatarSeenStageStore?>();
    if (kid == null || look == null || !isOn || store == null) return;
    final base = look.base;
    if (base is! PresetBase) return;
    final key = '${kid.id}|${base.name}|${look.stage}';
    if (_checked == key) return;
    _checked = key;
    unawaited(_celebrateIfNew(store, kid, base.name, look.stage));
  }

  Future<void> _celebrateIfNew(
    AvatarSeenStageStore store,
    Member kid,
    String nestling,
    int stage,
  ) async {
    final seen = await store.seen(widget.householdId, kid.id);
    if (seen != null && seen >= stage) return;
    await store.markSeen(widget.householdId, kid.id, stage);
    if (!mounted || stage == AvatarStage.egg) return;
    HatchCelebration.show(
      context,
      kid: kid,
      nestling: nestling,
      from: seen ?? AvatarStage.egg,
      to: stage,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
