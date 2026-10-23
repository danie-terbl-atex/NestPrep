import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/format/nest_dates.dart';
import '../model/fill_week_preview.dart';
import 'art/lunch_glyph.dart';

/// One school day in *Fill the week*'s review: what each compartment will
/// hold and where it came from — said in words on a tag, never by colour
/// alone (`FE-13`) — or that the day has gone and is left as it is.
class FillWeekDayCard extends StatelessWidget {
  const FillWeekDayCard({required this.day, super.key});

  final FillWeekDay day;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final note = day.hasGone
        ? FillWeekCopy.dayGone
        : (day.gainsSomething ? null : FillWeekCopy.dayUnchanged);
    return NestCard(
      variant: day.gainsSomething
          ? NestCardVariant.raised
          : NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(NestDates.weekdayName(day.date), style: nest.text.title),
          if (note != null) ...[
            const SizedBox(height: NestSpace.xs),
            Text(note, style: nest.text.caption),
          ],
          if (!day.hasGone)
            for (final slot in day.slots)
              NestListRow(
                leading: LunchSlotTile(
                  slot: slot.slot,
                  size: NestSize.avatarSmall,
                  isEmpty: slot.source is FillWeekPacked,
                ),
                title: slot.pick.name,
                subtitle: LunchCopy.slotName(slot.slot),
                footer: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _SourceTag(source: slot.source),
                ),
              ),
        ],
      ),
    );
  }
}

class _SourceTag extends StatelessWidget {
  const _SourceTag({required this.source});

  final FillWeekSource source;

  @override
  Widget build(BuildContext context) => switch (source) {
    FillWeekPacked() => const NestTag(
      label: FillWeekCopy.alreadyPacked,
      icon: LucideIcons.lock,
    ),
    FillWeekFromBox(:final boxName) => NestTag(
      label: FillWeekCopy.fromBox(boxName),
      tone: NestTagTone.accent,
      icon: LucideIcons.packageOpen,
    ),
    FillWeekByNestPrep() => const NestTag(
      label: FillWeekCopy.byNestPrep,
      tone: NestTagTone.success,
      icon: LucideIcons.utensils,
    ),
  };
}
