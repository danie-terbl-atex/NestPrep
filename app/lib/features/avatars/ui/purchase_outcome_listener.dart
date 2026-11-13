import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/avatar_copy.dart';
import '../model/avatar_catalogue.g.dart';
import '../state/avatar_studio_controller.dart';
import '../state/purchase_outcome.dart';

class PurchaseOutcomeListener extends StatefulWidget {
  const PurchaseOutcomeListener({
    required this.controller,
    required this.child,
    super.key,
  });

  final AvatarStudioController controller;
  final Widget child;

  @override
  State<PurchaseOutcomeListener> createState() =>
      _PurchaseOutcomeListenerState();
}

class _PurchaseOutcomeListenerState extends State<PurchaseOutcomeListener> {
  PurchaseOutcome? _shown;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(PurchaseOutcomeListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onChange);
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final outcome = widget.controller.outcome;
    if (outcome == null || identical(outcome, _shown) || !outcome.isOwned) {
      return;
    }
    _shown = outcome;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final accessory = outcome.accessory;
      final controller = widget.controller;
      final other = switch (controller.studio) {
        AsyncData(:final value)
            when controller.viewerMemberId != controller.memberId =>
          value.member.displayName,
        _ => null,
      };
      NestCelebration.show(
        context,
        title: other == null
            ? AvatarCopy.boughtTitle(accessory.label)
            : AvatarCopy.boughtTitleOf(other, accessory.label),
        message: other == null
            ? AvatarCopy.boughtBody
            : AvatarCopy.boughtBodyOf(other),
        picture: NestSticker(
          asset: avatarAssetPath(accessory.id),
          size: NestSize.stickerHero,
        ),
      );
      widget.controller.dismissOutcome();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
