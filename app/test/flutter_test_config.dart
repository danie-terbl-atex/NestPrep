import 'dart:async';

import 'package:nestprep/design/nest_kit.dart';

/// Runs before every test file under this folder. The welcome's orbit turns
/// for as long as it is on screen (design-system ADR-0006), and `pumpAndSettle`
/// waits for a screen with nothing scheduled — so the suite holds it still.
/// The one test of the turning itself clears this for its own body.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  NestMotion.debugHoldStill = true;
  await testMain();
}
