import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../model/photo_feed.dart';
import '../model/photo_update.dart';
import '../state/photo_feed_controller.dart';
import 'hub_clock.dart';
import 'hub_empty_note.dart';
import 'photo_update_card.dart';

/// What the feed shows once the shift and its photos have loaded: whose shift
/// and whether it is still going, then every photo, newest first. With none
/// yet it says when they will come, in place (`FE-08`).
class PhotoFeedView extends StatelessWidget {
  const PhotoFeedView({
    required this.feed,
    required this.controller,
    required this.memberById,
    super.key,
  });

  final PhotoFeed feed;
  final PhotoFeedController controller;
  final Member? Function(String memberId) memberById;

  Future<void> _remove(BuildContext context, PhotoUpdate update) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: NannyPhotoCopy.removeConfirm,
      message: NannyPhotoCopy.removeBody,
      confirmLabel: NannyPhotoCopy.removeAction,
      cancelLabel: NannyCopy.cancel,
      isDangerous: true,
    );
    if (confirmed != true) return;
    await controller.remove(update);
  }

  @override
  Widget build(BuildContext context) {
    final clock = context.read<HouseholdClock>();
    final shift = feed.shift!;
    final carer = memberById(shift.carerMemberId)?.displayName;
    final started = shift.startedAt;
    final sections = <Widget>[
      _FeedHeader(
        carer: memberById(shift.carerMemberId),
        title: NannyPhotoCopy.feedHeader(
          carer ?? NannyPhotoCopy.somebody,
          started == null
              ? NannyShiftCopy.summaryPending
              : clock.timeOf(started),
        ),
        isLive: feed.isLive,
      ),
      if (feed.updates.isEmpty)
        feed.isLive
            ? HubEmptyNote(
                title: NannyPhotoCopy.liveEmptyTitle,
                message: NannyPhotoCopy.liveEmptyBody(
                  carer ?? NannyPhotoCopy.somebody,
                ),
                icon: Icons.photo_camera_outlined,
              )
            : const HubEmptyNote(
                title: NannyPhotoCopy.endedEmptyTitle,
                message: NannyPhotoCopy.endedEmptyBody,
                icon: Icons.photo_outlined,
              ),
      for (final update in feed.updates)
        PhotoUpdateCard(
          key: ValueKey(update.id),
          photoId: update.photoId,
          caption: update.caption,
          byline: NannyPhotoCopy.from(
            memberById(update.byMemberId)?.displayName ??
                NannyPhotoCopy.somebody,
            _time(clock, update),
          ),
          childNames: [
            for (final childId in update.childIds)
              ?memberById(childId)?.displayName,
          ],
          onRemove: controller.mayRemove(update, isShiftOpen: feed.isLive)
              ? () => _remove(context, update)
              : null,
        ),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final (index, section) in sections.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: NestRiseIn(index: index, child: section),
          ),
      ],
    );
  }

  static String _time(HouseholdClock clock, PhotoUpdate update) {
    final at = update.createdAt;
    return at == null ? NannyPhotoCopy.pending : clock.timeOf(at);
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.carer,
    required this.title,
    required this.isLive,
  });

  final Member? carer;
  final String title;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final person = carer;
    return Row(
      children: [
        if (person != null) ...[
          NestAvatar(name: person.displayName, color: person.color),
          const SizedBox(width: NestSpace.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: nest.text.title),
              const SizedBox(height: NestSpace.xs),
              NestTag(
                label: isLive ? NannyPhotoCopy.live : NannyPhotoCopy.ended,
                tone: isLive ? NestTagTone.success : NestTagTone.neutral,
                icon: isLive ? Icons.circle : Icons.nights_stay_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
