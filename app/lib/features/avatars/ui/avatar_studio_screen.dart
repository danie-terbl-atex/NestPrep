import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../model/avatar_studio.dart';
import '../state/avatar_creation_controller.dart';
import '../state/avatar_keepsakes_controller.dart';
import '../state/avatar_studio_controller.dart';
import 'avatar_studio_tab.dart';
import 'create_tab.dart';
import 'keepsakes_tab.dart';
import 'nestlings_tab.dart';
import 'photo_tab.dart';
import 'purchase_outcome_listener.dart';
import 'studio_preview.dart';
import 'studio_tab_picker.dart';
import 'wardrobe_tab.dart';

class AvatarStudioScreen extends StatefulWidget {
  const AvatarStudioScreen({
    this.initialTab = AvatarStudioTab.nestlings,
    super.key,
  });

  final AvatarStudioTab initialTab;

  @override
  State<AvatarStudioScreen> createState() => _AvatarStudioScreenState();
}

class _AvatarStudioScreenState extends State<AvatarStudioScreen> {
  late AvatarStudioTab _tab = widget.initialTab;

  void _show(AvatarStudioTab tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AvatarStudioController>();
    final failure = controller.actionFailure;
    final isSelf = controller.viewerMemberId == controller.memberId;
    final studio = switch (controller.studio) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final isFamily =
        context.watch<HouseholdView?>()?.permissions.isFamily ?? false;
    final makes =
        context.watch<AvatarCreationController?>() != null &&
        ((studio?.creationsOn ?? true) || isFamily);
    final keeps = switch (context.watch<AvatarKeepsakesController?>()) {
      null => false,
      final shelf => makes || shelf.hasAny,
    };
    final tabs = [
      ...AvatarStudioTab.always,
      if (makes) AvatarStudioTab.create,
      if (keeps) AvatarStudioTab.keepsakes,
    ];
    final tab = tabs.contains(_tab) ? _tab : AvatarStudioTab.nestlings;
    return PurchaseOutcomeListener(
      controller: controller,
      child: NestScaffold(
        title: studio == null || isSelf
            ? AvatarCopy.yourTitle
            : AvatarCopy.title(studio.member.displayName),
        leading: backLeading(context),
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
                  onAction: controller.dismissActionFailure,
                ),
              ),
            if (controller.outcome case final outcome? when !outcome.isOwned)
              Padding(
                padding: const EdgeInsets.only(bottom: NestSpace.lg),
                child: NestBanner(
                  message: outcome.isTooSlow
                      ? AvatarCopy.tooSlow
                      : AvatarCopy.refused(outcome.reason),
                  tone: NestBannerTone.warning,
                  actionLabel: AppCopy.back,
                  onAction: controller.dismissOutcome,
                ),
              ),
            Expanded(
              child: NestAsyncView<AvatarStudio>(
                state: controller.studio,
                isEmpty: (_) => false,
                onRetry: controller.retry,
                emptyBuilder: (_) => const SizedBox.shrink(),
                dataBuilder: (context, studio) => ListView(
                  padding: const EdgeInsets.only(bottom: NestSpace.huge),
                  children: [
                    StudioPreview(
                      studio: studio,
                      isSelf: isSelf,
                      onUseInitial: controller.useInitial,
                    ),
                    const SizedBox(height: NestSpace.xl),
                    StudioTabPicker(tabs: tabs, selected: tab, onSelect: _show),
                    const SizedBox(height: NestSpace.xl),
                    switch (tab) {
                      AvatarStudioTab.nestlings => NestlingsTab(
                        studio: studio,
                        isSelf: isSelf,
                        onPick: controller.pickNestling,
                        onStage: controller.pickStage,
                      ),
                      AvatarStudioTab.photo => PhotoTab(
                        studio: studio,
                        isSaving: controller.isSavingPhoto,
                        onSave: controller.savePhoto,
                      ),
                      AvatarStudioTab.wardrobe => WardrobeTab(
                        studio: studio,
                        isSelf: isSelf,
                        isBuying: controller.isBuying,
                        onWear: controller.wear,
                        onBuy: controller.buy,
                      ),
                      AvatarStudioTab.create => CreateTab(
                        studio: studio,
                        isSelf: isSelf,
                        onUse: controller.useImage,
                        onShelf: keeps
                            ? () => _show(AvatarStudioTab.keepsakes)
                            : null,
                      ),
                      AvatarStudioTab.keepsakes => KeepsakesTab(
                        studio: studio,
                        isSelf: isSelf,
                        onUse: controller.useImage,
                        onMake: tabs.contains(AvatarStudioTab.create)
                            ? () => _show(AvatarStudioTab.create)
                            : null,
                      ),
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
