import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/week_load.dart';
import 'adult_load_card.dart';
import 'load_split_bar.dart';

/// The week once it is known: the bar, then a card per adult, then the
/// reminder that not everything is countable. Holds one key per adult so a
/// card can be captured to share — widget state, not data (`FE-07`).
class MentalLoadBody extends StatefulWidget {
  const MentalLoadBody({
    required this.week,
    required this.weekLabel,
    required this.onShare,
    super.key,
  });

  final WeekLoad week;
  final String weekLabel;

  /// Share this adult's card, drawn under this key.
  final void Function(AdultLoad adult, GlobalKey cardKey) onShare;

  @override
  State<MentalLoadBody> createState() => _MentalLoadBodyState();
}

class _MentalLoadBodyState extends State<MentalLoadBody> {
  final Map<String, GlobalKey> _keys = {};

  GlobalKey _keyFor(String memberId) =>
      _keys.putIfAbsent(memberId, () => GlobalKey(debugLabel: memberId));

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final week = widget.week;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(
          MentalLoadCopy.intro,
          style: nest.text.body.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.lg),
        if (week.adults.length > 1 && !week.isEmpty) ...[
          NestRiseIn(child: LoadSplitBar(week: week)),
          const SizedBox(height: NestSpace.lg),
        ],
        if (week.adults.length < 2) ...[
          const NestToneRow(
            icon: Icons.group_add_outlined,
            title: MentalLoadCopy.noAdultsTitle,
            subtitle: MentalLoadCopy.noAdultsBody,
          ),
          const SizedBox(height: NestSpace.lg),
        ],
        for (final (index, adult) in week.adults.indexed)
          Padding(
            key: ValueKey(adult.member.id),
            padding: const EdgeInsets.only(bottom: NestSpace.md),
            child: NestRiseIn(
              index: index + 1,
              child: AdultLoadCard(
                adult: adult,
                weekLabel: widget.weekLabel,
                shareKey: _keyFor(adult.member.id),
                onShare: () => widget.onShare(adult, _keyFor(adult.member.id)),
              ),
            ),
          ),
        const SizedBox(height: NestSpace.sm),
        Text(
          MentalLoadCopy.footnote,
          style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
        ),
      ],
    );
  }
}
