import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/welcome_tour/ui/welcome_tour_layer.dart';

/// Lets the welcome tour find its next component (welcome-tour ADR-0002).
///
/// `pumpAndSettle` alone stops too soon: the tour's search asks for a frame
/// as it polls, and the pump that runs the poll draws that frame in the same
/// breath, so the binding looks idle while the search is still going. This
/// steps time through the whole of the tour's patience, then settles.
Future<void> waitForTour(WidgetTester tester) async {
  const step = Duration(milliseconds: 100);
  final steps =
      WelcomeTourLayer.patience.inMilliseconds ~/ step.inMilliseconds + 2;
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
  await tester.pumpAndSettle();
}
