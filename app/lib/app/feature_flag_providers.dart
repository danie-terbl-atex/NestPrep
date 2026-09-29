import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../shared/flags/feature_flag_source.dart';
import '../shared/flags/feature_flags.dart';
import '../shared/flags/firestore_feature_flag_source.dart';

/// The one switchboard every screen reads with `context.watch<FeatureFlags>()`.
/// It starts at the safe defaults and follows `appConfig/flags` from there, so
/// nothing waits on a flag to draw.
List<SingleChildWidget> featureFlagProviders() => [
  Provider<FeatureFlagSource>(
    create: (context) => FirestoreFeatureFlagSource(
      context.read<FirebaseFirestore>(),
      isDebugBuild: kDebugMode,
    ),
  ),
  StreamProvider<FeatureFlags>(
    create: (context) => context.read<FeatureFlagSource>().watch(),
    initialData: const FeatureFlags.defaults(isDebugBuild: kDebugMode),
  ),
];
