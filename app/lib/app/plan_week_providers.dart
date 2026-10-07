import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/plan_week/data/callable_lunch_idea_drafter.dart';
import '../features/plan_week/data/callable_lunch_week_builder.dart';
import '../features/plan_week/data/firestore_lunch_aisle_source.dart';
import '../features/plan_week/data/lunch_aisle_source.dart';
import '../features/plan_week/data/lunch_idea_drafter.dart';
import '../features/plan_week/data/lunch_week_builder.dart';
import '../features/plan_week/data/packing_choice_store.dart';
import '../features/plan_week/data/secure_storage_packing_choice_store.dart';

/// *Plan my week*'s two callables (lunch-box ADR-0012), the shelves of
/// Checkers' lunchbox aisle it reads first (ADR-0013) and the packing choices
/// this phone remembers, in their own list so the app-wide graph changes by
/// one line.
List<SingleChildWidget> planWeekProviders() => [
  Provider<LunchIdeaDrafter>(
    create: (context) =>
        CallableLunchIdeaDrafter(context.read<FirebaseFunctions>()),
  ),
  Provider<LunchWeekBuilder>(
    create: (context) =>
        CallableLunchWeekBuilder(context.read<FirebaseFunctions>()),
  ),
  Provider<LunchAisleSource>(
    create: (context) =>
        FirestoreLunchAisleSource(context.read<FirebaseFirestore>()),
  ),
  Provider<PackingChoiceStore>(
    create: (context) => SecureStoragePackingChoiceStore(),
  ),
];
