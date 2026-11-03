import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/copy/cook_along_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../household/model/household_view.dart';
import '../../recipes/ui/recipe_picture.dart';
import '../data/photo_frame_directory.dart';
import '../data/photo_frame_repository.dart';
import '../model/frame_share_item.dart';
import '../model/photo_frame.dart';
import '../model/shared_page.dart';
import '../state/share_to_frame_controller.dart';

Future<void> showShareToFrameSheet({
  required BuildContext context,
  required FrameShareItem item,
}) {
  final view = context.read<HouseholdView>();
  final repository = context.read<PhotoFrameRepository>();
  final directory = context.read<PhotoFrameDirectory>();
  return showNestSheet<void>(
    context: context,
    title: PhotoFrameCopy.showOnFrame,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => ShareToFrameController(
        photoFrameRepository: repository,
        photoFrameDirectory: directory,
        householdId: view.household.id,
        item: item,
        isFamily: view.permissions.isFamily,
      ),
      child: const _ShareSheetBody(),
    ),
  );
}

class _ShareSheetBody extends StatelessWidget {
  const _ShareSheetBody();

  @override
  Widget build(BuildContext context) {
    final share = context.watch<ShareToFrameController>();
    final item = share.item;
    final beat = switch ((share.isFamily, item.isSendable, share.sentTo)) {
      (false, _, _) => const _Notice(
        icon: LucideIcons.lock,
        message: PhotoFrameCopy.shareOnlyFamily,
      ),
      (_, false, _) => const _Notice(
        icon: LucideIcons.unlink,
        message: PhotoFrameCopy.noLinkShared,
      ),
      (_, _, final sent?) => _Sent(frame: sent, item: item),
      _ => _Choose(share: share),
    };
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.isSendable) ...[
            switch (item) {
              FrameSharePage(:final page) => _PageRow(page: page),
              final FrameShareRecipe recipe => _RecipeRow(recipe: recipe),
            },
            const SizedBox(height: NestSpace.lg),
          ],
          AnimatedSwitcher(
            duration: NestMotion.of(context).standard,
            child: KeyedSubtree(key: ValueKey(beat.runtimeType), child: beat),
          ),
        ],
      ),
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({required this.page});

  final SharedPage page;

  @override
  Widget build(BuildContext context) {
    final site = page.site ?? '';
    final title = page.title;
    return NestListRow(
      title: title ?? site,
      subtitle: title == null ? null : site,
      leading: const NestIconTile(
        icon: LucideIcons.globe,
        tint: NestTileTint.lilac,
        size: NestSize.avatarMedium,
      ),
    );
  }
}

class _RecipeRow extends StatelessWidget {
  const _RecipeRow({required this.recipe});

  final FrameShareRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return NestListRow(
      title: recipe.name,
      subtitle: RecipeCopy.forPeople(recipe.people),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(NestRadius.sm),
        child: SizedBox.square(
          dimension: NestSize.avatarLarge,
          child: ExcludeSemantics(
            child: RecipePicture(path: recipe.cardPhotoPath),
          ),
        ),
      ),
    );
  }
}

class _Choose extends StatelessWidget {
  const _Choose({required this.share});

  final ShareToFrameController share;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final failure = share.failure;
    return switch (share.frames) {
      AsyncLoading() => const NestLoadingView(rows: 2),
      AsyncFailure(:final failure) => NestBanner(
        message: AppCopy.failure(failure),
        tone: NestBannerTone.danger,
        actionLabel: AppCopy.retry,
        onAction: share.retry,
      ),
      AsyncData(value: []) => const _Notice(
        icon: LucideIcons.tvMinimal,
        title: PhotoFrameCopy.noSharingFrames,
        message: PhotoFrameCopy.noSharingFramesBody,
      ),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failure != null) ...[
            NestBanner(message: _refusal(failure), tone: NestBannerTone.danger),
            const SizedBox(height: NestSpace.lg),
          ],
          if (value case [final only]) ...[
            NestButton(
              label: PhotoFrameCopy.showOn(only.name),
              icon: LucideIcons.tvMinimal,
              isLoading: share.sendingTo == only.id,
              onPressed: share.sendingTo == null && share.canOpen(only)
                  ? () => share.send(only)
                  : null,
            ),
            if (!share.canOpen(only)) ...[
              const SizedBox(height: NestSpace.sm),
              Text(
                CookAlongCopy.updateToCookAlong,
                textAlign: TextAlign.center,
                style: nest.text.caption,
              ),
            ],
          ] else ...[
            Text(PhotoFrameCopy.chooseFrame, style: nest.text.label),
            const SizedBox(height: NestSpace.sm),
            for (final frame in value)
              _FrameRow(
                key: ValueKey(frame.id),
                frame: frame,
                canOpen: share.canOpen(frame),
                isSending: share.sendingTo == frame.id,
                onTap: share.sendingTo == null ? () => share.send(frame) : null,
              ),
          ],
        ],
      ),
    };
  }

  static String _refusal(AppFailure failure) => switch (failure) {
    PhotoFrameFailure(problem: PhotoFrameProblem.notFamily) =>
      PhotoFrameCopy.shareOnlyFamily,
    _ => AppCopy.failure(failure),
  };
}

class _FrameRow extends StatelessWidget {
  const _FrameRow({
    required this.frame,
    required this.canOpen,
    required this.isSending,
    required this.onTap,
    super.key,
  });

  final PhotoFrame frame;
  final bool canOpen;
  final bool isSending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final c = nest.colors;
    return Semantics(
      enabled: canOpen,
      child: NestListRow(
        title: frame.name,
        titleStyle: canOpen
            ? null
            : nest.text.bodyStrong.copyWith(color: c.inkSecondary),
        subtitle: canOpen ? null : CookAlongCopy.updateToCookAlong,
        isSelected: isSending,
        leading: const NestIconTile(
          icon: LucideIcons.tvMinimal,
          tint: NestTileTint.butter,
          size: NestSize.avatarMedium,
        ),
        trailing: switch ((isSending, canOpen)) {
          (true, _) => SizedBox.square(
            dimension: NestSize.iconSmall,
            child: CircularProgressIndicator(
              strokeWidth: NestStroke.focus,
              color: c.ink,
            ),
          ),
          (_, true) => Icon(LucideIcons.chevronRight, color: c.inkTertiary),
          _ => null,
        },
        onTap: canOpen ? onTap : null,
      ),
    );
  }
}

class _Sent extends StatelessWidget {
  const _Sent({required this.frame, required this.item});

  final PhotoFrame frame;
  final FrameShareItem item;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const NestRiseIn(
          child: Center(
            child: NestIconTile(
              icon: LucideIcons.monitorUp,
              tint: NestTileTint.basil,
              size: NestSize.mark,
              iconSize: NestSize.iconMark,
            ),
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        Text(
          PhotoFrameCopy.openingOn(frame.name),
          textAlign: TextAlign.center,
          style: nest.text.headline,
        ),
        if (item is FrameShareRecipe) ...[
          const SizedBox(height: NestSpace.sm),
          Text(
            CookAlongCopy.sentBody,
            textAlign: TextAlign.center,
            style: nest.text.bodySecondary,
          ),
        ],
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: PhotoFrameCopy.done,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message, this.title});

  final IconData icon;
  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final titleText = title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: NestIconTile(
            icon: icon,
            tint: NestTileTint.butter,
            size: NestSize.avatarLarge,
          ),
        ),
        const SizedBox(height: NestSpace.lg),
        if (titleText != null) ...[
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: nest.text.headline,
          ),
          const SizedBox(height: NestSpace.sm),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: nest.text.bodySecondary,
        ),
        const SizedBox(height: NestSpace.xl),
        NestButton(
          label: PhotoFrameCopy.done,
          variant: NestButtonVariant.tonal,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
