import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_slot.dart';
import 'package:nestprep/features/plan_week/model/lunch_pack_boxes.dart';

import '../../../support/checkers_fakes_for_plan_week.dart';

/// How many lunches one pack does when nobody reckoned it (lunch-box
/// ADR-0028 §3).
void main() {
  test("takes the shop's count first", () {
    final yoghurt = planWeekProduct('Yoghurt 6 x 100g', packCount: 6);
    expect(LunchPackBoxes.of(yoghurt, LunchSlot.snack), 6);
  });

  test('reads a bag of fruit or veg by its weight', () {
    expect(
      LunchPackBoxes.of(planWeekProduct('Apples 1kg'), LunchSlot.fruit),
      6,
    );
    expect(
      LunchPackBoxes.of(planWeekProduct('Naartjies 1,5 kg'), LunchSlot.fruit),
      10,
    );
    expect(
      LunchPackBoxes.of(planWeekProduct('Baby carrots 500g'), LunchSlot.veg),
      5,
    );
  });

  test('never guesses a snack by weight, and never goes past the most', () {
    expect(
      LunchPackBoxes.of(planWeekProduct('Popcorn 1kg'), LunchSlot.snack),
      1,
    );
    expect(
      LunchPackBoxes.of(planWeekProduct('Apples 10kg'), LunchSlot.fruit),
      LunchPackBoxes.most,
    );
    expect(LunchPackBoxes.of(planWeekProduct('Apples'), LunchSlot.fruit), 1);
    expect(
      LunchPackBoxes.of(planWeekProduct('Mini apple 80g'), LunchSlot.fruit),
      1,
    );
  });

  test('reads grams from kilos and grams alike', () {
    expect(LunchPackBoxes.gramsIn('Pears 1.5kg bag'), 1500);
    expect(LunchPackBoxes.gramsIn('Grapes 500 g'), 500);
    expect(LunchPackBoxes.gramsIn('Rusks'), isNull);
  });
}
