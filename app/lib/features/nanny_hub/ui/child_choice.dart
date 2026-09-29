import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/member.dart';

/// Which children an entry is about, as chips with each child's initials in
/// their colour — the name is always written too (`FE-13`).
class ChildChoice extends StatelessWidget {
  const ChildChoice({
    required this.children,
    required this.chosen,
    required this.onChanged,
    super.key,
  });

  final List<Member> children;
  final Set<String> chosen;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          NannyShiftCopy.whoFor,
          style: nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final child in children)
              NestChip(
                label: child.displayName,
                isSelected: chosen.contains(child.id),
                icon: chosen.contains(child.id) ? Icons.check : null,
                onTap: () => onChanged(
                  chosen.contains(child.id)
                      ? ({...chosen}..remove(child.id))
                      : {...chosen, child.id},
                ),
              ),
          ],
        ),
      ],
    );
  }
}
