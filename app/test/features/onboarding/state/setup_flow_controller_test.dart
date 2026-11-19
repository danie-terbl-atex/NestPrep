import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/onboarding/model/onboarding_step.dart';
import 'package:nestprep/features/onboarding/state/setup_flow_controller.dart';

/// The setup step's panels (onboarding ADR-0001): forward and back within
/// family, calendar and the payoff, the bar's step for each, and who was
/// last added.
void main() {
  test('runs family, calendar, ready and stops at each end', () {
    final flow = SetupFlowController();
    addTearDown(flow.dispose);
    expect(flow.panel, SetupPanel.family);
    flow.back();
    expect(flow.panel, SetupPanel.family);

    flow
      ..next()
      ..next()
      ..next();
    expect(flow.panel, SetupPanel.ready);

    flow.back();
    expect(flow.panel, SetupPanel.calendar);
  });

  test('the bar is on family, then the calendar, and stays full on the '
      'payoff', () {
    final flow = SetupFlowController();
    addTearDown(flow.dispose);
    expect(flow.step, CreatorStep.family);
    flow.next();
    expect(flow.step, CreatorStep.calendar);
    flow.next();
    expect(flow.step, CreatorStep.calendar);
    expect(flow.step.index, flow.step.count - 1);
  });

  test('counts who was added, and remembers the last', () {
    final flow = SetupFlowController();
    addTearDown(flow.dispose);
    expect(flow.lastAdded, isNull);
    flow
      ..noteAdded('Lulu')
      ..noteAdded('Gran');
    expect(flow.added, 2);
    expect(flow.lastAdded, 'Gran');
  });

  test('every step reads as its place in the way in', () {
    expect(CreatorStep.account.label, 'Step 1 of 5 · Your account');
    expect(CreatorStep.calendar.label, 'Step 5 of 5 · Your calendar');
    expect(InviteeStep.join.label, 'Step 3 of 3 · Join your family');
  });
}
