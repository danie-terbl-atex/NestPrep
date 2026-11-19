import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nestprep/design/nest_kit.dart';

/// Twig's actions on a real device (design-system ADR-0026): the frames each
/// one costs while it plays, and that he schedules none at rest. Run in
/// profile mode, where the numbers mean something:
///
///     flutter drive --profile -d <device> \
///       --driver=test_driver/frames_driver.dart \
///       --target=integration_test/twig_frames_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every action plays within the frame budget and then rests', (
    tester,
  ) async {
    var key = 0;
    late StateSetter replay;
    var action = NestTwigAction.arrive;
    var pose = NestTwigPose.welcome;
    await tester.pumpWidget(
      MaterialApp(
        theme: nestThemeData(NestTheme.light()),
        home: Scaffold(
          body: Center(
            child: NestTwigWarmUp(
              child: StatefulBuilder(
                builder: (context, setState) {
                  replay = setState;
                  return NestTwig(
                    pose: pose,
                    size: NestSize.twigLarge,
                    action: action,
                    actionKey: key,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final each in NestTwigAction.values) {
      for (final eachPose in [NestTwigPose.welcome, NestTwigPose.celebrate]) {
        await binding.watchPerformance(() async {
          for (var run = 0; run < 3; run++) {
            replay(() {
              action = each;
              pose = eachPose;
              key++;
            });
            await tester.pumpAndSettle();
          }
        }, reportKey: '${each.name}_${eachPose.name}');
      }
    }

    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
