import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/groceries/model/product_match.dart';

/// Runs before every test file under this folder. The welcome's orbit turns
/// for as long as it is on screen (design-system ADR-0006), and `pumpAndSettle`
/// waits for a screen with nothing scheduled — so the suite holds it still.
/// The one test of the turning itself clears this for its own body.
///
/// Every shop is connected here whatever the source ships with (shops
/// ADR-0004), so the shop features are tested while a store build holds them
/// off; the tests of the switch itself set their own.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  NestMotion.debugHoldStill = true;
  ProductRetailer.debugSwitchOverride = everyShopConnected;
  await testMain();
}

bool everyShopConnected(ProductRetailer shop, TargetPlatform platform) => true;
