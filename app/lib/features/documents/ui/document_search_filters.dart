import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/vault_copy.dart';
import '../../../shared/ui/member_filter.dart';
import '../../household/model/member.dart';
import '../model/document_search.dart';

/// The search screen's filters: whose documents, which tag, and only what
/// expires soon. Each row scrolls sideways on its own, so a household with
/// many tags does not push the results off the screen (`FE-14`).
class DocumentSearchFilters extends StatelessWidget {
  const DocumentSearchFilters({
    required this.query,
    required this.owners,
    required this.tags,
    required this.onOwner,
    required this.onTag,
    required this.onExpiringSoon,
    super.key,
  });

  final DocumentQuery query;

  /// The people whose vaults are searchable right now — none while locked.
  final List<Member> owners;
  final List<String> tags;
  final ValueChanged<OwnerFilter> onOwner;
  final ValueChanged<String> onTag;
  final ValueChanged<bool> onExpiringSoon;

  @override
  Widget build(BuildContext context) {
    final owner = query.owner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MemberFilter(
          members: owners,
          selectedId: switch (owner) {
            AnyOwner() => null,
            HouseholdOwner() => '',
            MemberOwner(:final memberId) => memberId,
          },
          everybodyLabel: VaultCopy.searchEveryone,
          onSelect: (memberId) => onOwner(
            memberId == null ? OwnerFilter.anyone : MemberOwner(memberId),
          ),
          extraChips: [
            NestChip(
              label: VaultCopy.searchHousehold,
              icon: LucideIcons.folder,
              isSelected: owner is HouseholdOwner,
              onTap: () => onOwner(OwnerFilter.household),
            ),
          ],
        ),
        const SizedBox(height: NestSpace.sm),
        SizedBox(
          height: NestSize.controlSmall,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              NestChip(
                label: VaultCopy.searchExpiring,
                icon: LucideIcons.clock,
                isSelected: query.expiringSoonOnly,
                onTap: () => onExpiringSoon(!query.expiringSoonOnly),
              ),
              for (final tag in tags) ...[
                const SizedBox(width: NestSpace.sm),
                NestChip(
                  label: tag,
                  icon: LucideIcons.tag,
                  isSelected: query.tag?.toLowerCase() == tag.toLowerCase(),
                  onTap: () => onTag(tag),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
