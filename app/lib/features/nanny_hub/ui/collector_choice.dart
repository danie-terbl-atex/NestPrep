import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';
import '../model/pickup_collector.dart';
import '../model/pickup_person.dart';

/// Who collects, as chips: the people listed for this child first, then the
/// household's grown-ups — and, on a changed day, nobody at all. A person not
/// listed for the child is never offered, so a run cannot name somebody the
/// door check would turn away.
class CollectorChoice extends StatelessWidget {
  const CollectorChoice({
    required this.people,
    required this.adults,
    required this.chosen,
    required this.onChanged,
    this.allowsNobody = false,
    super.key,
  });

  /// Listed for the child in question.
  final List<PickupPerson> people;

  /// The household's grown-ups — the carer, a parent.
  final List<Member> adults;
  final PickupCollector? chosen;
  final ValueChanged<PickupCollector> onChanged;
  final bool allowsNobody;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final options = <(PickupCollector, String)>[
      for (final person in people) (CollectedByPerson(person.id), person.name),
      for (final adult in adults)
        (CollectedByMember(adult.id), adult.displayName),
      if (allowsNobody)
        (const NobodyCollects(), NannyPickupCopy.nobodyCollects),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          NannyPickupCopy.whoCollects,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        if (people.isEmpty) ...[
          Text(NannyPickupCopy.noCollectorsYet, style: nest.text.caption),
          const SizedBox(height: NestSpace.sm),
        ],
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final (collector, label) in options)
              NestChip(
                label: label,
                isSelected: collector == chosen,
                icon: collector == chosen ? LucideIcons.check : null,
                onTap: () => onChanged(collector),
              ),
          ],
        ),
      ],
    );
  }
}
