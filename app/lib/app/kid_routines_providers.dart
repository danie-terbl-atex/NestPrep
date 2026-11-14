import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/kid_routines/data/firestore_kid_routine_repository.dart';
import '../features/kid_routines/data/kid_routine_repository.dart';

/// Kid routines' part of the app-wide graph (kid-routines ADR-0001), behind
/// its interface so a widget test substitutes a fake.
List<SingleChildWidget> kidRoutinesProviders() => [
  Provider<KidRoutineRepository>(
    create: (context) =>
        FirestoreKidRoutineRepository(context.read<FirebaseFirestore>()),
  ),
];
