import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/two_homes/data/callable_two_homes_directory.dart';
import '../features/two_homes/data/firestore_two_homes_repository.dart';
import '../features/two_homes/data/two_homes_directory.dart';
import '../features/two_homes/data/two_homes_repository.dart';

/// Two homes' repository and callables, each behind its interface so a widget
/// test substitutes a fake (foundation ADR-0006). In their own file so the
/// provider graph gains one line (household ADR-0004). Its switch,
/// `coParenting`, is on the one flag seam (foundation ADR-0014).
List<SingleChildWidget> twoHomesProviders() => [
  Provider<TwoHomesRepository>(
    create: (context) =>
        FirestoreTwoHomesRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<TwoHomesDirectory>(
    create: (context) =>
        CallableTwoHomesDirectory(context.read<FirebaseFunctions>()),
  ),
];
