import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/photo_frame_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/cook_along_copy.dart';
import '../../household/model/household_view.dart';
import 'cook_along_frame_picture.dart';

Future<void> showCookAlongTeaserSheet({required BuildContext context}) async {
  final householdId = context.read<HouseholdView>().household.id;
  final router = GoRouter.of(context);
  final wantsFrame = await showNestSheet<bool>(
    context: context,
    builder: (_) => const CookAlongTeaserSheet(),
  );
  if (wantsFrame ?? false) {
    await router.push<void>(PhotoFrameRoute.pathFor(householdId));
  }
}

class CookAlongTeaserSheet extends StatelessWidget {
  const CookAlongTeaserSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const NestRiseIn(child: CookAlongFramePicture()),
          const SizedBox(height: NestSpace.xl),
          const Center(
            child: NestTag(
              label: CookAlongCopy.homeTag,
              tone: NestTagTone.accent,
              icon: LucideIcons.sparkles,
            ),
          ),
          const SizedBox(height: NestSpace.sm),
          Text(
            CookAlongCopy.teaserTitle,
            textAlign: TextAlign.center,
            style: nest.text.headline,
          ),
          const SizedBox(height: NestSpace.xl),
          const _Promise(
            icon: LucideIcons.listOrdered,
            tint: NestTileTint.butter,
            text: CookAlongCopy.teaserSteps,
          ),
          const _Promise(
            icon: LucideIcons.timer,
            tint: NestTileTint.guava,
            text: CookAlongCopy.teaserTimers,
          ),
          const _Promise(
            icon: LucideIcons.users,
            tint: NestTileTint.basil,
            text: CookAlongCopy.teaserScaled,
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: CookAlongCopy.linkFrame,
            icon: LucideIcons.tvMinimal,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: NestSpace.sm),
          NestButton(
            label: CookAlongCopy.notNow,
            variant: NestButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.icon, required this.tint, required this.text});

  final IconData icon;
  final NestTileTint tint;
  final String text;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NestSpace.xs),
      child: Row(
        children: [
          NestIconTile(
            icon: icon,
            tint: tint,
            size: NestSize.avatarMedium,
            iconSize: NestSize.iconSmall,
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(child: Text(text, style: nest.text.body)),
        ],
      ),
    );
  }
}
