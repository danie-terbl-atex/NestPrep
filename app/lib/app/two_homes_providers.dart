import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/two_homes/data/callable_two_homes_directory.dart';
import '../features/two_homes/data/firestore_two_homes_repository.dart';
import '../features/two_homes/data/two_homes_directory.dart';
import '../features/two_homes/data/two_homes_repository.dart';
import '../shared/flags/feature_flag_source.dart';
import '../shared/flags/feature_flags.dart';
import '../shared/flags/firestore_feature_flag_source.dart';

/// Two homes' repository and callables, each behind its interface so a widget
/// test substitutes a fake (foundation ADR-0006), and the feature flags every
/// V2 capability reads (verdict 003). In their own file so the provider graph
/// gains one line (household ADR-0004).
List<SingleChildWidget> twoHomesProviders() => [
  Provider<FeatureFlagSource>(
    create: (context) =>
        FirestoreFeatureFlagSource(context.read<FirebaseFirestore>()),
  ),
  // Starts at the build's defaults and follows the document; a failed read
  // leaves the defaults standing (the source logs why).
  StreamProvider<FeatureFlags>(
    create: (context) => context.read<FeatureFlagSource>().watch(),
    initialData: FeatureFlags.defaults(),
  ),
  Provider<TwoHomesRepository>(
    create: (context) =>
        FirestoreTwoHomesRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<TwoHomesDirectory>(
    create: (context) =>
        CallableTwoHomesDirectory(context.read<FirebaseFunctions>()),
  ),
];
