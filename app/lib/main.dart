import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'app/backend_target.dart';
import 'app/firebase_bootstrap.dart';
import 'app/nestprep_app.dart';
import 'features/observability/crash_reporting.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The IANA database every household's timezone is resolved against
  // (foundation ADR-0007). Loaded once, before anything reads a date.
  tz_data.initializeTimeZones();

  final target = BackendTarget.fromEnvironment();
  final services = await bootstrapFirebase(target);
  // After Firebase, before the first frame — so a crash in the first build is
  // still reported (observability ADR-0001).
  await CrashReporting.install(target);

  runApp(NestPrepApp(services: services));
}
