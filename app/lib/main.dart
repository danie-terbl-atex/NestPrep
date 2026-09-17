import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'app/backend_target.dart';
import 'app/firebase_bootstrap.dart';
import 'app/nestprep_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The IANA database every household's timezone is resolved against
  // (foundation ADR-0007). Loaded once, before anything reads a date.
  tz_data.initializeTimeZones();
  final services = await bootstrapFirebase(BackendTarget.fromEnvironment());
  runApp(NestPrepApp(services: services));
}
