import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';
import '../model/handover_entry.dart';
import 'handover_row.dart';

/// The shift's log, newest first: when, what, about whom, and the photo if
/// there is one. The carer's own entries open for a change; nothing else
/// does. When nothing is logged yet it says how, in place (`FE-08`).
class HandoverTimeline extends StatelessWidget {
  const HandoverTimeline({
    required this.entries,
    required this.children,
    required this.canEdit,
    required this.onEdit,
    super.key,
  });

  final List<HandoverEntry> entries;
  final List<Member> children;
  final bool Function(HandoverEntry entry) canEdit;
  final ValueChanged<HandoverEntry> onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final names = {for (final child in children) child.id: child.displayName};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(NannyCopy.logSoFar, style: nest.text.title),
        const SizedBox(height: NestSpace.sm),
        if (entries.isEmpty)
          Text(
            NannyCopy.logEmpty,
            style: nest.text.bodySecondary.copyWith(
              color: nest.colors.inkTertiary,
            ),
          ),
        for (final entry in entries)
          Padding(
            key: ValueKey(entry.id),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: HandoverRow(
              entry: entry,
              childNames: [
                for (final id in entry.childIds) ?names[id],
              ],
              onTap: canEdit(entry) ? () => onEdit(entry) : null,
            ),
          ),
      ],
    );
  }
}
