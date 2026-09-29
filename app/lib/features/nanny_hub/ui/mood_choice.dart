import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/handover_kind.dart';
import '../model/handover_mood.dart';
import 'handover_look.dart';

/// How the children seemed, as five chips — one tap, and tapping the chosen
/// one again takes it back. On a mood entry it leads the sheet; on any other
/// it is an optional line.
class MoodChoice extends StatelessWidget {
  const MoodChoice({
    required this.mood,
    required this.isProminent,
    required this.onChanged,
    super.key,
  });

  final HandoverMood? mood;
  final bool isProminent;
  final ValueChanged<HandoverMood?> onChanged;

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          NannyShiftCopy.kindName(HandoverKind.mood),
          style: isProminent
              ? nest.text.title
              : nest.text.label.copyWith(color: nest.colors.inkSecondary),
        ),
        const SizedBox(height: NestSpace.sm),
        Wrap(
          spacing: NestSpace.sm,
          runSpacing: NestSpace.sm,
          children: [
            for (final option in HandoverMood.values)
              NestChip(
                label: NannyShiftCopy.moodName(option),
                icon: option.icon,
                isSelected: option == mood,
                onTap: () => onChanged(option == mood ? null : option),
              ),
          ],
        ),
      ],
    );
  }
}
