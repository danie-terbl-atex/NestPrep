import 'package:flutter/material.dart';

import '../../design/nest_kit.dart';
import '../../features/household/model/member.dart';

/// Narrows a list to one member, or to everybody.
///
/// A lens, not a place: which member is showing lives on the controller and
/// never in the document (`FE-07`). Todos and the calendar ask the same
/// question, which is why it lives here (`ENG-02`).
class MemberFilter extends StatelessWidget {
  const MemberFilter({
    required this.members,
    required this.selectedId,
    required this.onSelect,
    required this.everybodyLabel,
    super.key,
  });

  final List<Member> members;

  /// Null means everybody, which is a real answer and the usual one.
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  /// What "no filter" is called here — the two features word it differently.
  final String everybodyLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: NestSize.controlSmall,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          NestChip(
            label: everybodyLabel,
            isSelected: selectedId == null,
            onTap: () => onSelect(null),
          ),
          for (final member in members) ...[
            const SizedBox(width: NestSpace.sm),
            NestChip(
              label: member.displayName,
              isSelected: selectedId == member.id,
              onTap: () => onSelect(member.id),
            ),
          ],
        ],
      ),
    );
  }
}
