import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import 'avatar_studio_tab.dart';

class StudioTabPicker extends StatelessWidget {
  const StudioTabPicker({
    required this.tabs,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<AvatarStudioTab> tabs;
  final AvatarStudioTab selected;
  final ValueChanged<AvatarStudioTab> onSelect;

  static IconData iconOf(AvatarStudioTab tab) => switch (tab) {
    AvatarStudioTab.nestlings => LucideIcons.egg,
    AvatarStudioTab.photo => LucideIcons.camera,
    AvatarStudioTab.wardrobe => LucideIcons.shirt,
    AvatarStudioTab.create => LucideIcons.wandSparkles,
    AvatarStudioTab.keepsakes => LucideIcons.images,
  };

  @override
  Widget build(BuildContext context) =>
      tabs.length <= AvatarStudioTab.always.length
      ? NestSegmentedControl<AvatarStudioTab>(
          segments: [
            for (final tab in tabs) NestSegment(value: tab, label: tab.label),
          ],
          selected: selected,
          onSelect: onSelect,
        )
      : NestChipRail<AvatarStudioTab>(
          segments: [
            for (final tab in tabs)
              NestSegment(value: tab, label: tab.label, icon: iconOf(tab)),
          ],
          selected: selected,
          onSelect: onSelect,
        );
}
