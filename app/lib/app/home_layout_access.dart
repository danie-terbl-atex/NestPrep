import 'package:flutter/foundation.dart';

abstract final class HomeLayoutAccess {
  static const defineName = 'NESTPREP_LAYOUT_SWITCH';

  // Demo-login builds are the ones installed on our own phones for testing,
  // so they carry the switch too; a store build has neither define.
  static const isAvailable =
      kDebugMode ||
      bool.fromEnvironment('NESTPREP_DEMO_LOGINS') ||
      bool.fromEnvironment(defineName);
}
