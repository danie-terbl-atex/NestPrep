import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/guide_spot.dart';
import '../model/nanny_hub_view.dart';
import '../state/nanny_hub_controller.dart';
import 'guide_spot_card.dart';
import 'guide_spot_sheet.dart';
import 'hub_empty_note.dart';
import 'nanny_hub_page.dart';

/// The house guide: a photo of each place a carer might need to find, with
/// where exactly underneath. Whoever writes the hub adds, changes and removes
/// places; everybody else reads them.
class HouseGuideScreen extends StatelessWidget {
  const HouseGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NannyHubController>();
    final canEdit = controller.access.canEdit;
    return NannyHubPage(
      title: NannyCopy.houseGuide,
      floatingAction: canEdit
          ? NestButton(
              label: NannyCopy.addSpot,
              icon: LucideIcons.camera,
              isExpanded: false,
              onPressed: () => _edit(context, controller),
            )
          : null,
      builder: (context, view) =>
          _GuideBody(view: view, controller: controller),
    );
  }

  static Future<void> _edit(
    BuildContext context,
    NannyHubController controller, [
    GuideSpot? spot,
  ]) async {
    final outcome = await showGuideSpotSheet(
      context: context,
      existing: spot,
      onPick: controller.pickPhoto,
    );
    if (outcome == null) return;
    if (outcome.isRemoval && spot != null) {
      await controller.edit.removeGuideSpot(spot.id, photoId: spot.photoId);
      return;
    }
    await controller.edit.saveGuideSpot(
      spotId: spot?.id,
      title: outcome.title,
      note: outcome.note,
      photo: outcome.photo,
      currentPhotoId: spot?.photoId,
    );
  }
}

class _GuideBody extends StatelessWidget {
  const _GuideBody({required this.view, required this.controller});

  final NannyHubView view;
  final NannyHubController controller;

  @override
  Widget build(BuildContext context) {
    final canEdit = controller.access.canEdit;
    final guide = view.hub.guide;
    if (guide.isEmpty) {
      return ListView(
        children: [
          HubEmptyNote(
            icon: LucideIcons.images,
            title: NannyCopy.guideEmptyTitle,
            message: canEdit
                ? NannyCopy.guideEmptyBody
                : NannyCopy.guideEmptyCarer,
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        for (final (index, spot) in guide.indexed)
          Padding(
            key: ValueKey(spot.id),
            padding: const EdgeInsets.only(bottom: NestSpace.lg),
            child: NestRiseIn(
              index: index,
              child: GuideSpotCard(
                spot: spot,
                onEdit: canEdit
                    ? () => HouseGuideScreen._edit(context, controller, spot)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
