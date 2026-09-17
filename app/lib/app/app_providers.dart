import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/diagnostics/data/firestore_ping_repository.dart';
import '../features/diagnostics/data/ping_repository.dart';

/// The app-wide dependency graph: the platform instance and one repository per
/// feature, each behind its interface so tests substitute a fake
/// (foundation ADR-0006). Per-screen controllers are created at their route.
List<SingleChildWidget> appProviders(FirebaseFirestore firestore) => [
  Provider<FirebaseFirestore>.value(value: firestore),
  Provider<PingRepository>(
    create: (context) =>
        FirestorePingRepository(context.read<FirebaseFirestore>()),
  ),
];
