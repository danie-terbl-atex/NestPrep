import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../accounts/ui/account_menu_button.dart';
import '../model/frame_photo.dart';
import '../state/frame_photos_controller.dart';
import 'frame_photo_tile.dart';

class FramePhotosScreen extends StatelessWidget {
  const FramePhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FramePhotosController>();
    final showsAlbum =
        controller.isLoaded && (!controller.isEmpty || controller.isAdding);
    return NestScaffold(
      title: PhotoFrameCopy.photosTitle,
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
          if (!showsAlbum) _Notice(controller: controller),
          Expanded(
            child: NestAsyncView<List<FramePhoto>>(
              state: controller.photos,
              isEmpty: (photos) => photos.isEmpty && !controller.isAdding,
              onRetry: controller.retry,
              emptyBuilder: (context) => NestEmptyView(
                title: PhotoFrameCopy.photosEmptyTitle,
                message: PhotoFrameCopy.photosEmptyBody,
                icon: LucideIcons.images,
                actionLabel: PhotoFrameCopy.addPhotos,
                onAction: controller.addFromLibrary,
              ),
              dataBuilder: (context, photos) =>
                  _Album(photos: photos, controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.controller});

  final FramePhotosController controller;

  @override
  Widget build(BuildContext context) {
    final failure = controller.actionFailure;
    final report = controller.lastAdd;
    final banner = failure != null
        ? NestBanner(
            message: AppCopy.failure(failure),
            tone: NestBannerTone.danger,
            actionLabel: AppCopy.back,
            onAction: controller.dismissActionFailure,
          )
        : report != null && (report.skipped > 0 || report.hitLimit)
        ? NestBanner(
            message: PhotoFrameCopy.addReport(report),
            tone: NestBannerTone.warning,
            actionLabel: PhotoFrameCopy.done,
            onAction: controller.dismissReport,
          )
        : null;
    if (banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.lg),
      child: banner,
    );
  }
}

class _Album extends StatelessWidget {
  const _Album({required this.photos, required this.controller});

  final List<FramePhoto> photos;
  final FramePhotosController controller;

  Future<void> _confirmRemove(BuildContext context, FramePhoto photo) async {
    final confirmed = await showNestConfirm(
      context: context,
      title: PhotoFrameCopy.removePhotoConfirm,
      message: PhotoFrameCopy.removePhotoBody,
      confirmLabel: PhotoFrameCopy.removePhoto,
      cancelLabel: PhotoFrameCopy.keep,
      isDangerous: true,
    );
    if (confirmed == true) await controller.remove(photo);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final adding = controller.adding;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Notice(controller: controller),
              Text(PhotoFrameCopy.photosIntro, style: nest.text.bodySecondary),
              const SizedBox(height: NestSpace.md),
              Text(
                PhotoFrameCopy.photoCount(photos.length),
                style: nest.text.label,
              ),
              const SizedBox(height: NestSpace.md),
              NestButton(
                label: adding == null
                    ? PhotoFrameCopy.addPhotos
                    : PhotoFrameCopy.adding(adding.current, adding.total),
                icon: LucideIcons.imagePlus,
                variant: NestButtonVariant.tonal,
                isLoading: adding != null,
                onPressed: controller.isFull || controller.isBusy
                    ? null
                    : controller.addFromLibrary,
              ),
              if (controller.isFull) ...[
                const SizedBox(height: NestSpace.sm),
                Text(PhotoFrameCopy.albumFullHint, style: nest.text.caption),
              ],
              const SizedBox(height: NestSpace.lg),
            ],
          ),
        ),
        SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisSpacing: NestSpace.sm,
            crossAxisSpacing: NestSpace.sm,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return FramePhotoTile(
              key: ValueKey(photo.id),
              photo: photo,
              position: index + 1,
              controller: controller,
              onTap: controller.isBusy
                  ? null
                  : () => _confirmRemove(context, photo),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: NestSpace.huge)),
      ],
    );
  }
}
