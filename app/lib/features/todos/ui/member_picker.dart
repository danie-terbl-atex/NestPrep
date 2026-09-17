import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';

/// Chooses who something is for. No selection means *anyone*, which is a real
/// answer and not an empty one — so it is offered as its own choice rather than
/// left as the absence of one.
///
/// Todos is the first use; the calendar is the second, and it moves to a shared
/// home then (`ENG-02`).
class MemberPicker extends StatelessWidget {
  const MemberPicker({
    required this.members,
    required this.selectedIds,
    required this.onChanged,
    this.anyoneLabel = AppCopy.todosAnyone,
    super.key,
  });

  final List<Member> members;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final String anyoneLabel;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Wrap(
      spacing: NestSpace.sm,
      runSpacing: NestSpace.sm,
      children: [
        NestChip(
          label: anyoneLabel,
          isSelected: selectedIds.isEmpty,
          onTap: () => onChanged(const []),
        ),
        for (final member in members)
          _MemberChip(
            member: member,
            isSelected: selectedIds.contains(member.id),
            swatch: nest.members.of(member.color),
            onTap: () => onChanged(_toggled(member.id)),
          ),
      ],
    );
  }

  List<String> _toggled(String memberId) {
    final next = [...selectedIds];
    if (next.contains(memberId)) {
      next.remove(memberId);
    } else {
      next.add(memberId);
    }
    return next;
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.member,
    required this.isSelected,
    required this.swatch,
    required this.onTap,
  });

  final Member member;
  final bool isSelected;
  final MemberSwatch swatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: member.displayName,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? swatch.fill : nest.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NestRadius.pill),
          side: BorderSide(
            color: isSelected ? swatch.fill : nest.colors.outline,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NestRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpace.md,
              vertical: NestSpace.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NestAvatar(
                  name: member.displayName,
                  color: member.color,
                  size: NestSize.iconMedium,
                ),
                const SizedBox(width: NestSpace.sm),
                Text(
                  member.displayName,
                  style: nest.text.label.copyWith(
                    color: isSelected
                        ? swatch.onFill
                        : nest.colors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
