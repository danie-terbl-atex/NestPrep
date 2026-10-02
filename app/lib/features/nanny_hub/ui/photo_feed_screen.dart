import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../state/nanny_hub_controller.dart';
import '../state/photo_feed_controller.dart';
import 'nanny_hub_screen.dart';
import 'photo_feed_view.dart';

/// The parents' live feed of one shift's photos (nanny-hub ADR-0004): newest
/// first, each arriving the moment the carer sends it. The same screen keeps a
/// finished shift's photos under its summary.
class PhotoFeedScreen extends StatelessWidget {
  const PhotoFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<PhotoFeedController>();
    final hub = context.watch<NannyHubController>();
    final failure = feed.actionFailure;
    return NestScaffold(
      title: NannyPhotoCopy.feedTitle,
      leading: backLeading(context),
      trailing: const [EmergencyLinkButton()],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: feed.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView(
              state: feed.feed,
              isEmpty: (value) => value.isGone,
              onRetry: feed.retry,
              emptyBuilder: (_) => const NestEmptyView(
                title: NannyPhotoCopy.goneTitle,
                message: NannyPhotoCopy.goneBody,
                icon: LucideIcons.calendarX,
              ),
              dataBuilder: (context, value) => PhotoFeedView(
                feed: value,
                controller: feed,
                memberById: hub.memberById,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
