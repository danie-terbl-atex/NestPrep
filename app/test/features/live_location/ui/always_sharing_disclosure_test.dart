import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/live_location/ui/always_sharing_flow.dart';

import '../../../support/pump_screen.dart';

const _motion = 'motion sensors';

Future<void> _pumpDisclosure(WidgetTester tester) => pumpScreen(
  tester,
  const Scaffold(body: SingleChildScrollView(child: AlwaysSharingDisclosure())),
  providers: const [],
);

void main() {
  testWidgets(
    'Android never mentions motion sensors, since it asks for no activity '
    'recognition',
    (tester) async {
      await _pumpDisclosure(tester);
      expect(find.textContaining(_motion), findsNothing);
      expect(find.textContaining('in the background'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('iPhone says it uses motion sensors before iOS asks about them', (
    tester,
  ) async {
    await _pumpDisclosure(tester);
    expect(find.textContaining(_motion), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
