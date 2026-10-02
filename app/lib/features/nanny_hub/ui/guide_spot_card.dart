import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/guide_spot.dart';
import 'nanny_photo.dart';

/// One place in the house guide: its photo across the top, what is there in
/// big letters, and where exactly underneath.
class GuideSpotCard extends StatelessWidget {
  const GuideSpotCard({required this.spot, required this.onEdit, super.key});

  final GuideSpot spot;

  /// Null when the viewer may not change the guide.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final photoId = spot.photoId;
    final note = spot.note;
    final edit = onEdit;
    return NestCard(
      padding: const EdgeInsets.all(NestSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photoId != null) ...[
            NannyPhoto(photoId: photoId, label: spot.title),
            const SizedBox(height: NestSpace.md),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spot.title, style: nest.text.title),
                    if (note != null) Text(note, style: nest.text.body),
                  ],
                ),
              ),
              if (edit != null)
                NestIconButton(
                  icon: LucideIcons.pencil,
                  label: NannyCopy.editSpot,
                  variant: NestIconButtonVariant.plain,
                  onPressed: edit,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
