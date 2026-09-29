import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/chore_points/data/callable_points_directory.dart';
import '../features/chore_points/data/firestore_points_repository.dart';
import '../features/chore_points/data/firestore_reward_repository.dart';
import '../features/chore_points/data/points_directory.dart';
import '../features/chore_points/data/points_repository.dart';
import '../features/chore_points/data/reward_repository.dart';

/// Todos phase 2's part of the app-wide graph (todos ADR-0003): a child's
/// stars (read only — only Functions write them), the reward shelf and its
/// requests, and the two parent decisions as callables. Each behind its
/// interface, so a widget test substitutes a fake.
///
/// Its own list, spread into `appProviders`, so the shared file changes by
/// one line.
List<SingleChildWidget> chorePointsProviders() => [
  Provider<PointsRepository>(
    create: (context) =>
        FirestorePointsRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<RewardRepository>(
    create: (context) =>
        FirestoreRewardRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<PointsDirectory>(
    create: (context) =>
        CallablePointsDirectory(context.read<FirebaseFunctions>()),
  ),
];
