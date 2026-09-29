import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../shared/flags/feature_flag_source.dart';
import '../shared/flags/feature_flags_controller.dart';
import '../shared/flags/firestore_feature_flag_source.dart';

/// The V2 switches, app-wide (foundation ADR-0014): one source, one
/// controller every screen reads. Its own list, so the shared graph changes
/// by one line — and the next V2 feature adds nothing here but an enum value.
List<SingleChildWidget> featureFlagProviders() => [
  Provider<FeatureFlagSource>(
    create: (context) =>
        FirestoreFeatureFlagSource(context.read<FirebaseFirestore>()),
  ),
  ChangeNotifierProvider<FeatureFlagsController>(
    create: (context) =>
        FeatureFlagsController(source: context.read<FeatureFlagSource>()),
  ),
];
