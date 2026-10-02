import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../family_profiles/model/member_health.dart';
import '../../family_profiles/ui/allergy_names.dart';
import '../model/child_in_care.dart';
import 'hub_empty_note.dart';

/// The children, each a row that says the one thing a carer must not miss
/// before opening the card: a severe allergy, or that allergies are not
/// shared with them. When there are none yet it says how to add one, in
/// place (`FE-08`).
class ChildrenList extends StatelessWidget {
  const ChildrenList({
    required this.children,
    required this.healthOf,
    required this.onOpen,
    super.key,
  });

  final List<ChildInCare> children;
  final AsyncState<MemberHealth>? Function(String memberId) healthOf;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: NannyCopy.children),
        const SizedBox(height: NestSpace.sm),
        if (children.isEmpty)
          const HubEmptyNote(
            icon: LucideIcons.baby,
            title: NannyCopy.noChildrenTitle,
            message: NannyCopy.noChildrenBody,
          ),
        for (final child in children)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: _ChildRow(
              key: ValueKey(child.memberId),
              child: child,
              takesMedicine: switch (healthOf(child.memberId)) {
                AsyncData(:final value) => value.medications.isNotEmpty,
                _ => false,
              },
              onTap: () => onOpen(child.memberId),
            ),
          ),
      ],
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({
    required this.child,
    required this.takesMedicine,
    required this.onTap,
    super.key,
  });

  final ChildInCare child;
  final bool takesMedicine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final member = child.member;
    final food = child.food;
    final severe = switch (food) {
      AsyncData(:final value) => [
        for (final allergy in value.allergies)
          if (allergy.severity.isSevere) allergyName(allergy),
      ],
      _ => const <String>[],
    };
    return NestCard(
      variant: NestCardVariant.flat,
      padding: const EdgeInsets.all(NestSpace.md),
      onTap: onTap,
      child: Row(
        children: [
          NestAvatar(
            name: member.displayName,
            color: member.color,
            size: NestSize.avatarLarge,
          ),
          const SizedBox(width: NestSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: NestTheme.of(context).text.title,
                ),
                const SizedBox(height: NestSpace.xs),
                Wrap(
                  spacing: NestSpace.xs,
                  runSpacing: NestSpace.xs,
                  children: [
                    if (food == null)
                      const NestTag(
                        label: NannyCopy.allergiesHiddenTitle,
                        icon: LucideIcons.lock,
                        tone: NestTagTone.warning,
                      ),
                    for (final name in severe)
                      NestTag(
                        label: name,
                        icon: LucideIcons.siren,
                        tone: NestTagTone.danger,
                      ),
                    if (takesMedicine)
                      const NestTag(
                        label: NannyCopy.medication,
                        icon: LucideIcons.pill,
                        tone: NestTagTone.accent,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight),
        ],
      ),
    );
  }
}
