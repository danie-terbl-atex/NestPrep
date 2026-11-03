import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'app/backend_target.dart';
import 'app/firebase_bootstrap.dart';
import 'app/font_licences.dart';
import 'app/nestprep_app.dart';
import 'features/live_location/data/method_channel_location_engine.dart';
import 'features/observability/crash_reporting.dart';
import 'shared/log/best_effort.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The IANA database every household's timezone is resolved against
  // (foundation ADR-0007). Loaded once, before anything reads a date.
  tz_data.initializeTimeZones();
  // The bundled fonts' own licences, beside the packages' (accounts ADR-0005).
  registerFontLicences();

  final target = BackendTarget.fromEnvironment();
  final services = await bootstrapFirebase(target);
  // After Firebase, before the first frame — so a crash in the first build is
  // still reported (observability ADR-0001).
  await CrashReporting.install(target);
  // The phone's always-on engine waits for this before it writes on iOS,
  // where it shares this process's Firestore (live-location ADR-0005).
  await bestEffort(
    'location engine ready',
    code: 'engine-ready-failed',
    run: MethodChannelLocationEngine().ready,
  );

  runApp(NestPrepApp(services: services));
}
