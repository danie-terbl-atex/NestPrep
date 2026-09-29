import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/handover_entry.dart';
import 'handover_look.dart';
import 'hub_clock.dart';
import 'nanny_photo.dart';

/// One line of the handover log: when, what, about whom, how they seemed,
/// what was said, and the photo.
class HandoverRow extends StatelessWidget {
  const HandoverRow({
    required this.entry,
    required this.childNames,
    required this.onTap,
    super.key,
  });

  final HandoverEntry entry;
  final List<String> childNames;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final note = entry.note;
    final mood = entry.mood;
    final photoId = entry.photoId;
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.md),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NestIconTile(
            icon: entry.kind.icon,
            tint: entry.kind.tint,
            size: NestSize.avatarMedium,
            iconSize: NestSize.iconMedium,
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${clock.timeOf(entry.at)} · '
                  '${NannyCopy.kindName(entry.kind)}',
                  style: nest.text.bodyStrong,
                ),
                if (childNames.isNotEmpty)
                  Text(childNames.join(', '), style: nest.text.caption),
                if (mood != null) ...[
                  const SizedBox(height: NestSpace.xs),
                  NestTag(
                    label: NannyCopy.moodName(mood),
                    icon: mood.icon,
                    tone: NestTagTone.accent,
                  ),
                ],
                if (note != null) ...[
                  const SizedBox(height: NestSpace.xs),
                  Text(note, style: nest.text.body),
                ],
                if (photoId != null) ...[
                  const SizedBox(height: NestSpace.sm),
                  NannyPhoto(
                    photoId: photoId,
                    label: NannyCopy.withPhoto,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
