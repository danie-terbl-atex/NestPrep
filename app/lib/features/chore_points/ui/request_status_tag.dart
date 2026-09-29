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
        Icons.more_horiz_rounded,
      ),
      RequestStatus.waiting => (
        PointsCopy.kidRequestWaiting,
        NestTagTone.accent,
        Icons.hourglass_top_rounded,
      ),
      RequestStatus.fulfilled => (
        PointsCopy.kidRequestFulfilled,
        NestTagTone.success,
        Icons.celebration_rounded,
      ),
      RequestStatus.declined => (
        PointsCopy.kidRequestDeclined,
        NestTagTone.neutral,
        Icons.undo_rounded,
      ),
      RequestStatus.refused => (
        PointsCopy.kidRequestRefused(request.refusal),
        NestTagTone.warning,
        Icons.info_outline_rounded,
      ),
    };
    return NestTag(label: label, tone: tone, icon: icon);
  }
}
