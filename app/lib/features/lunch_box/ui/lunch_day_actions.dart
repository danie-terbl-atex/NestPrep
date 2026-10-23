import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/flags/feature_flags_controller.dart';
import '../model/lunch_board.dart';
import '../model/lunch_day.dart';
import 'lunch_flows.dart';
import 'lunch_packed_today.dart';

/// What can be done to the day on show, under its photo card (lunch-box
/// ADR-0022): pack one of the child's go-to boxes into it (ADR-0003), and —
/// when it is today and the pantry is on — mark it packed (ADR-0006). Only
/// for somebody who may change lunches; the board does not build it
/// otherwise.
class LunchDayActions extends StatelessWidget {
  const LunchDayActions({
    required this.childWeek,
    required this.day,
    super.key,
  });

  final LunchChildWeek childWeek;
  final LunchDay day;

  @override
  Widget build(BuildContext context) {
    final flags = context.watch<FeatureFlagsController?>();
    final hasPantry = flags?.isOn(FeatureFlag.lunchPantry) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NestSpace.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: NestButton(
            label: LunchCopy.packFavourite,
            icon: LucideIcons.heart,
            variant: NestButtonVariant.ghost,
            size: NestButtonSize.small,
            isExpanded: false,
            onPressed: () => LunchFlows.packFavourite(
              context,
              childWeek: childWeek,
              day: day,
            ),
          ),
        ),
        if (hasPantry) LunchPackedToday(childWeek: childWeek, day: day),
      ],
    );
  }
}
