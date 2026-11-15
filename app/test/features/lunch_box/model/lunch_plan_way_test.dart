import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/lunch_box/model/lunch_plan_way.dart';

void main() {
  List<LunchPlanWay> offered({
    bool hasTwig = true,
    bool hasPantry = true,
    bool isFull = false,
  }) => LunchPlanWay.offered(
    hasTwig: hasTwig,
    hasPantry: hasPantry,
    isFull: isFull,
  );

  test('Twig leads', () {
    expect(offered(), [
      LunchPlanWay.twig,
      LunchPlanWay.boxes,
      LunchPlanWay.pantry,
    ]);
  });

  test('a packed week leaves only Twig, who plans every child', () {
    expect(offered(isFull: true), [LunchPlanWay.twig]);
    expect(offered(isFull: true, hasTwig: false), isEmpty);
  });

  test('without Twig or the pantry, the boxes are the one way', () {
    expect(offered(hasTwig: false, hasPantry: false), [LunchPlanWay.boxes]);
  });
}
