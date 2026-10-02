import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/checkers_copy.dart';
import '../model/checkers_area.dart';

/// Chooses the city the Checkers matches come from. Never asks for location:
/// a phone whose owner already allowed it is used without this sheet.
Future<void> showCheckersAreaSheet({
  required BuildContext context,
  required CheckersArea? current,
  required Future<void> Function(CheckersArea area) onChoose,
}) => showNestSheet<void>(
  context: context,
  title: CheckersCopy.areaTitle,
  builder: (sheetContext) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        CheckersCopy.areaBody,
        style: NestTheme.of(sheetContext).text.bodySecondary,
      ),
      const SizedBox(height: NestSpace.md),
      Flexible(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final area in CheckersArea.values)
              NestListRow(
                key: ValueKey(area),
                title: area.label,
                isSelected: area == current,
                trailing: area == current
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onChoose(area);
                },
              ),
          ],
        ),
      ),
    ],
  ),
);
