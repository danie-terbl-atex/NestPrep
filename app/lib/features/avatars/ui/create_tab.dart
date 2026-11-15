import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/household_view.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/paywall_page.dart';
import '../model/avatar_creation.dart';
import '../model/avatar_studio.dart';
import '../model/creation_allowance.dart';
import '../state/avatar_creation_controller.dart';
import '../state/creation_step.dart';
import 'avatar_creations_switch.dart';
import 'buddy_composer.dart';
import 'creation_hatching.dart';
import 'creation_menu.dart';
import 'creation_ready_view.dart';
import 'creation_refused_view.dart';
import 'creation_too_slow_view.dart';
import 'reference_composer.dart';

class CreateTab extends StatefulWidget {
  const CreateTab({
    required this.studio,
    required this.isSelf,
    required this.onUse,
    required this.onShelf,
    this.now,
    super.key,
  });

  final AvatarStudio studio;
  final bool isSelf;
  final Future<void> Function(String hash) onUse;
  final VoidCallback? onShelf;
  final DateTime Function()? now;

  static PremiumFeature featureOf(CreationRecipe recipe) =>
      recipe == CreationRecipe.portrait
      ? PremiumFeature.avatarPortrait
      : PremiumFeature.avatarCreate;

  @override
  State<CreateTab> createState() => _CreateTabState();
}

class _CreateTabState extends State<CreateTab> {
  CreationRecipe? _open;
  CreationStep? _paywalled;

  Future<void> _pick(
    AvatarCreationController creation,
    CreationRecipe recipe,
  ) async {
    if (recipe == CreationRecipe.portrait) {
      await creation.makePortrait();
      return;
    }
    setState(() => _open = recipe);
  }

  void _offerPaywall(CreationStep step, {required bool canBuy}) {
    if (!canBuy ||
        identical(step, _paywalled) ||
        step is! CreationRefused ||
        step.reason != CreationRefusal.premiumRequired) {
      return;
    }
    _paywalled = step;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        showPaywall(context, feature: CreateTab.featureOf(step.recipe)),
      );
    });
  }

  Future<void> _done(AvatarCreationController creation) async {
    setState(() => _open = null);
    await creation.startOver();
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final creation = context.watch<AvatarCreationController>();
    final view = context.watch<HouseholdView?>();
    final studio = widget.studio;
    final canBuy = view != null;
    final isFamily = view?.permissions.isFamily ?? false;
    final step = creation.step;
    _offerPaywall(step, canBuy: canBuy);
    final failure = creation.actionFailure;
    final banner = failure == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: NestBanner(
              message: AppCopy.failure(failure),
              tone: NestBannerTone.danger,
              actionLabel: AppCopy.back,
              onAction: creation.dismissActionFailure,
            ),
          );
    if (!studio.creationsOn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestCard(
            variant: NestCardVariant.flat,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AvatarCreationCopy.offTitle, style: nest.text.title),
                const SizedBox(height: NestSpace.xs),
                Text(AvatarCreationCopy.offBody, style: nest.text.body),
              ],
            ),
          ),
          const AvatarCreationsSwitch(
            padding: EdgeInsets.only(top: NestSpace.md),
          ),
        ],
      );
    }
    final clock = HouseholdClock(studio.timeZone, now: widget.now);
    final today = clock.today;
    final left = CreationAllowance.from(creation.recent, clock: clock).left;
    final isSpent = left == 0;
    final note = switch (left) {
      0 => AvatarCreationCopy.noneLeft(
        CreationRefusedView.nextMonthFrom(today),
      ),
      final count? when count > 0 => AvatarCreationCopy.picturesLeft(count),
      _ => null,
    };
    final body = switch (step) {
      CreationSending() ||
      CreationWaiting() => CreationHatching(studio: studio, step: step),
      CreationReady() => CreationReadyView(
        studio: studio,
        householdId: creation.householdId,
        ready: step,
        onUse: () async {
          await widget.onUse(step.imageHash);
          await _done(creation);
        },
        onKeep: () => _done(creation),
      ),
      CreationRefused() => CreationRefusedView(
        refused: step,
        today: today,
        onAgain: creation.startOver,
        onPremium: canBuy
            ? () => showPaywall(
                context,
                feature: CreateTab.featureOf(step.recipe),
              )
            : null,
      ),
      CreationTooSlow() => CreationTooSlowView(
        studio: studio,
        onShelf: widget.onShelf == null
            ? null
            : () async {
                widget.onShelf!();
                await _done(creation);
              },
        onDone: () => _done(creation),
      ),
      CreationComposing() => switch (_open) {
        CreationRecipe.buddy => BuddyComposer(
          onBack: () => setState(() => _open = null),
          onMake: (buddy, style, extra) =>
              creation.makeBuddy(buddy, extra: extra, style: style),
        ),
        final CreationRecipe recipe
            when recipe == CreationRecipe.drawing ||
                recipe == CreationRecipe.pet =>
          ReferenceComposer(
            key: ValueKey('compose-${recipe.name}'),
            recipe: recipe,
            onBack: () => setState(() => _open = null),
            onMake: (style, jpeg) => creation.makeFromPicture(
              recipe: recipe,
              jpeg: jpeg,
              style: style,
            ),
          ),
        _ => CreationMenu(
          note: note,
          isSpent: isSpent,
          offersPortrait: isFamily && widget.isSelf,
          onPick: (recipe) => _pick(creation, recipe),
        ),
      },
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [?banner, body],
    );
  }
}
