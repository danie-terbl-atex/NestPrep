import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/points_copy.dart';
import '../model/reward_request.dart';

/// Where one request for a reward stands, as a tag: words, an icon and a
/// tone, never the tone alone (`FE-13`). Read by a child, so in a child's
/// words.
class RequestStatusTag extends StatelessWidget {
  const RequestStatusTag({required this.request, super.key});

  final RewardRequest request;

  @override
  Widget build(BuildContext context) {
    final (label, tone, icon) = switch (request.status) {
      null => (
        PointsCopy.kidRequestCounting,
        NestTagTone.neutral,
        LucideIcons.ellipsis,
      ),
      RequestStatus.waiting => (
        PointsCopy.kidRequestWaiting,
        NestTagTone.accent,
        LucideIcons.hourglass,
      ),
      RequestStatus.fulfilled => (
        PointsCopy.kidRequestFulfilled,
        NestTagTone.success,
        LucideIcons.partyPopper,
      ),
      RequestStatus.declined => (
        PointsCopy.kidRequestDeclined,
        NestTagTone.neutral,
        LucideIcons.undo2,
      ),
      RequestStatus.refused => (
        PointsCopy.kidRequestRefused(request.refusal),
        NestTagTone.warning,
        LucideIcons.info,
      ),
    };
    return NestTag(label: label, tone: tone, icon: icon);
  }
}
