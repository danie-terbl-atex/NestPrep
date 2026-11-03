import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/photo_frame_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/photo_frame.dart';
import '../state/frame_photos_controller.dart';
import '../state/photo_frames_controller.dart';
import 'frame_album_card.dart';
import 'frame_edit_sheet.dart';
import 'frame_link_sheet.dart';
import 'photo_frame_card.dart';

class PhotoFramesScreen extends StatelessWidget {
  const PhotoFramesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PhotoFramesController>();
    final failure = controller.actionFailure;
    return NestScaffold(
      title: PhotoFrameCopy.title,
      leading: context.canPop()
          ? NestIconButton(
              icon: LucideIcons.arrowLeft,
              label: AppCopy.back,
              variant: NestIconButtonVariant.plain,
              onPressed: context.pop,
            )
          : null,
      trailing: const [AccountMenuButton()],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null && !controller.isInSheet)
            Padding(
              padding: const EdgeInsets.only(bottom: NestSpace.lg),
              child: NestBanner(
                message: AppCopy.failure(failure),
                tone: NestBannerTone.danger,
                actionLabel: AppCopy.back,
                onAction: controller.dismissActionFailure,
              ),
            ),
          Expanded(
            child: NestAsyncView<List<PhotoFrame>>(
              state: controller.frames,
              isEmpty: (frames) => frames.isEmpty,
              onRetry: controller.retry,
              emptyBuilder: (context) => NestEmptyView(
                title: PhotoFrameCopy.emptyTitle,
                message: PhotoFrameCopy.emptyBody,
                icon: LucideIcons.tvMinimal,
                actionLabel: PhotoFrameCopy.link,
                onAction: () => showFrameLinkSheet(
                  context: context,
                  controller: controller,
                ),
              ),
              dataBuilder: (context, frames) =>
                  _Frames(frames: frames, controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _Frames extends StatelessWidget {
  const _Frames({required this.frames, required this.controller});

  final List<PhotoFrame> frames;
  final PhotoFramesController controller;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final album = context.watch<FramePhotosController>();
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(PhotoFrameCopy.intro, style: nest.text.bodySecondary),
        const SizedBox(height: NestSpace.lg),
        for (final frame in frames)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: PhotoFrameCard(
              key: ValueKey(frame.id),
              frame: frame,
              helper: controller.helperById(frame.panels.helperMemberId),
              clock: clock,
              onTap: () => showFrameEditSheet(
                context: context,
                controller: controller,
                frame: frame,
                albumIsEmpty: album.isEmpty,
              ),
            ),
          ),
        const SizedBox(height: NestSpace.sm),
        NestButton(
          label: PhotoFrameCopy.link,
          icon: LucideIcons.plus,
          variant: NestButtonVariant.tonal,
          onPressed: () =>
              showFrameLinkSheet(context: context, controller: controller),
        ),
        const SizedBox(height: NestSpace.xl),
        FrameAlbumCard(
          controller: album,
          onTap: () => context.push(
            PhotoFrameRoute.photosPathFor(controller.householdId),
          ),
        ),
      ],
    );
  }
}
