import 'package:flutter/widgets.dart';

import 'app/backend_target.dart';
import 'app/firebase_bootstrap.dart';
import 'app/nestprep_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firestore = await bootstrapFirebase(BackendTarget.fromEnvironment());
  runApp(NestPrepApp(firestore: firestore));
}
