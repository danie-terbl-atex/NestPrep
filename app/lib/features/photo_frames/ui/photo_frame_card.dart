import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/photo_frame_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../../../shared/time/household_clock.dart';
import '../../household/model/member.dart';
import '../model/photo_frame.dart';

class PhotoFrameCard extends StatelessWidget {
  const PhotoFrameCard({
    required this.frame,
    required this.helper,
    required this.clock,
    required this.onTap,
    super.key,
  });

  final PhotoFrame frame;
  final Member? helper;
  final HouseholdClock clock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = clock.now;
    final isQuiet = frame.isQuietAt(now);
    return NestCard(
      variant: NestCardVariant.flat,
      padding: EdgeInsets.zero,
      child: NestListRow(
        title: frame.name,
        subtitle: _shows(),
        leading: const NestIconTile(
          icon: LucideIcons.tvMinimal,
          tint: NestTileTint.butter,
        ),
        trailing: const Icon(LucideIcons.chevronRight),
        footer: _SeenLine(
          label: _seen(now, isQuiet: isQuiet),
          isQuiet: isQuiet,
        ),
        onTap: onTap,
      ),
    );
  }

  String _shows() {
    final panels = frame.panels;
    final helperName = helper?.displayName;
    final parts = [
      if (panels.calendar) PhotoFrameCopy.calendar,
      if (panels.todos) PhotoFrameCopy.todos,
      if (panels.meals) PhotoFrameCopy.meals,
      if (panels.lunch) PhotoFrameCopy.lunch,
      if (panels.helperMemberId != null)
        helperName == null
            ? PhotoFrameCopy.helperTitle
            : PhotoFrameCopy.helperDay(helperName),
    ];
    return parts.isEmpty ? PhotoFrameCopy.showsNothing : parts.join(' · ');
  }

  String _seen(DateTime now, {required bool isQuiet}) {
    final seen = frame.lastSeenAt;
    if (seen == null) {
      return isQuiet
          ? PhotoFrameCopy.notHeardSinceLinked
          : PhotoFrameCopy.waitingToHear;
    }
    return isQuiet
        ? PhotoFrameCopy.lastSeen(
            NestDates.moment(
              clock.dateOf(seen),
              clock.today,
              clock.minutesOfDay(seen),
            ),
          )
        : PhotoFrameCopy.seen(NestDates.ago(now.difference(seen)));
  }
}

class _SeenLine extends StatelessWidget {
  const _SeenLine({required this.label, required this.isQuiet});

  final String label;
  final bool isQuiet;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final ink = isQuiet ? nest.colors.warning : nest.colors.inkSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isQuiet ? LucideIcons.clockAlert : LucideIcons.clock,
          size: NestSize.iconSmall,
          color: ink,
        ),
        const SizedBox(width: NestSpace.xs),
        Expanded(
          child: Text(label, style: nest.text.label.copyWith(color: ink)),
        ),
      ],
    );
  }
}
