import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/time/household_clock.dart';
import '../model/handover_kind.dart';
import '../model/summary_moment.dart';
import 'handover_look.dart';
import 'hub_clock.dart';

/// One moment of a finished shift, as the summary kept it. An incident is
/// drawn in the danger tone, and says so in words too (`FE-13`).
class SummaryMomentRow extends StatelessWidget {
  const SummaryMomentRow({
    required this.moment,
    required this.childNames,
    super.key,
  });

  final SummaryMoment moment;
  final List<String> childNames;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final clock = context.read<HouseholdClock>();
    final note = moment.note;
    final mood = moment.mood;
    final heading =
        '${clock.timeOf(moment.at)} · ${NannyCopy.kindName(moment.kind)}';
    final line = [
      if (childNames.isNotEmpty) childNames.join(', '),
      if (mood != null) NannyCopy.moodName(mood),
      if (moment.hasPhoto) NannyCopy.withPhoto,
    ].join(' · ');
    if (moment.kind == HandoverKind.incident) {
      return NestToneRow(
        icon: moment.kind.icon,
        tone: NestTagTone.danger,
        title: heading,
        subtitle: [?note, if (line.isNotEmpty) line].join('\n'),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NestIconTile(
          icon: moment.kind.icon,
          tint: moment.kind.tint,
          size: NestSize.avatarSmall + NestSpace.sm,
          iconSize: NestSize.iconSmall,
        ),
        const SizedBox(width: NestSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading, style: nest.text.bodyStrong),
              if (note != null) Text(note, style: nest.text.body),
              if (line.isNotEmpty) Text(line, style: nest.text.caption),
            ],
          ),
        ),
      ],
    );
  }
}
