import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/appearance.dart';
import '../state/appearance_controller.dart';

/// Auto, Day or Night for this phone, on the More tab (design-system
/// ADR-0024). The app turns as soon as a segment is tapped.
class AppearanceCard extends StatelessWidget {
  const AppearanceCard({super.key});

  /// Three glyphs and three names do not fit a phone's width at large text;
  /// past this the names stand alone rather than being cut short.
  static const _glyphsUpToScale = 1.5;

  static const _choices = [
    (Appearance.auto, AppearanceCopy.auto, LucideIcons.sunMoon),
    (Appearance.day, AppearanceCopy.day, LucideIcons.sun),
    (Appearance.night, AppearanceCopy.night, LucideIcons.moon),
  ];

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final controller = context.watch<AppearanceController>();
    final withGlyphs =
        MediaQuery.textScalerOf(context).scale(1) <= _glyphsUpToScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionHeader(title: AppearanceCopy.section),
        const SizedBox(height: NestSpace.md),
        NestSegmentedControl<Appearance>(
          segments: [
            for (final (value, label, icon) in _choices)
              NestSegment(
                value: value,
                label: label,
                icon: withGlyphs ? icon : null,
              ),
          ],
          selected: controller.appearance,
          onSelect: controller.choose,
        ),
        const SizedBox(height: NestSpace.sm),
        Text(
          AppearanceCopy.hint,
          style: nest.text.caption.copyWith(color: nest.colors.inkTertiary),
        ),
      ],
    );
  }
}
