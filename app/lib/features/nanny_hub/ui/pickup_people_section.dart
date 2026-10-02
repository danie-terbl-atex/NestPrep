import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';
import '../model/nanny_pickups.dart';
import '../model/pickup_person.dart';
import 'collector_avatar.dart';

/// Who may collect, child by child, with the photo first. A child nobody is
/// listed for says so in the warning tone — an empty list at the door means
/// "release to nobody", and it must read that way. The add control sits
/// beside that message, never replaced by it (`FE-08`).
class PickupPeopleSection extends StatelessWidget {
  const PickupPeopleSection({
    required this.children,
    required this.pickups,
    required this.onAdd,
    required this.onEdit,
    super.key,
  });

  final List<Member> children;
  final NannyPickups pickups;

  /// Null for anybody who is not family.
  final VoidCallback? onAdd;
  final ValueChanged<PickupPerson>? onEdit;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final edit = onEdit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestSectionHeader(
          title: NannyPickupCopy.whoMayCollect,
          actionIcon: onAdd == null ? null : LucideIcons.userPlus,
          actionLabel: onAdd == null ? null : NannyPickupCopy.addPerson,
          onAction: onAdd,
        ),
        if (onAdd != null && pickups.people.isEmpty) ...[
          const SizedBox(height: NestSpace.xs),
          Text(NannyPickupCopy.addPersonHint, style: nest.text.bodySecondary),
        ],
        for (final child in children) ...[
          const SizedBox(height: NestSpace.md),
          Text(
            child.displayName,
            style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
          ),
          const SizedBox(height: NestSpace.sm),
          if (pickups.allowedFor(child.id).isEmpty)
            NestToneRow(
              icon: LucideIcons.ban,
              tone: NestTagTone.warning,
              title: NannyPickupCopy.nobodyListed(child.displayName),
            ),
          for (final person in pickups.allowedFor(child.id))
            Padding(
              key: ValueKey('${child.id}/${person.id}'),
              padding: const EdgeInsets.only(bottom: NestSpace.sm),
              child: NestCard(
                variant: NestCardVariant.flat,
                padding: EdgeInsets.zero,
                child: NestListRow(
                  leading: CollectorAvatar(
                    look: (
                      name: person.name,
                      detail: person.relationship,
                      person: person,
                      member: null,
                    ),
                  ),
                  title: person.name,
                  subtitle: [person.relationship, ?person.idNote].join(' · '),
                  trailing: edit == null
                      ? null
                      : const Icon(LucideIcons.pencil),
                  onTap: edit == null ? null : () => edit(person),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
