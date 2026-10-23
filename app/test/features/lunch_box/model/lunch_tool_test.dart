import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_tool.dart';

import '../../../support/fake_feature_flag_source.dart';

/// Who is offered each way to plan a week and each tool beside the board
/// (lunch-box ADR-0022) — the answer the board and the welcome tour share
/// (welcome-tour ADR-0001).
void main() {
  test('somebody who may only look is offered the prep list and the V2 '
      'tools anybody may open, and nothing that plans', () {
    expect(
      LunchTool.openOf(LunchTool.values, canEdit: false, flags: TestFlags.on),
      [LunchTool.prep, LunchTool.pantry, LunchTool.budget],
    );
  });

  test('an editor is offered everything while the switches are on', () {
    expect(
      LunchTool.openOf(LunchTool.values, canEdit: true, flags: TestFlags.on),
      LunchTool.values,
    );
  });

  test('a switch off takes its tools away, never the core ones', () {
    expect(
      LunchTool.openOf(LunchTool.values, canEdit: true, flags: TestFlags.off),
      [LunchTool.fillWeek, LunchTool.prep, LunchTool.library, LunchTool.share],
    );
  });

  test('the prep list, budget and plan my week are premium', () {
    expect(
      {
        for (final tool in LunchTool.values)
          if (tool.isPremium) tool,
      },
      {LunchTool.prep, LunchTool.budget, LunchTool.planMyWeek},
    );
  });
}
