import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/lunch_box/data/firestore_lunch_budget_repository.dart';
import '../features/lunch_box/data/firestore_lunch_choices_repository.dart';
import '../features/lunch_box/data/firestore_lunch_pantry_repository.dart';
import '../features/lunch_box/data/lunch_budget_repository.dart';
import '../features/lunch_box/data/lunch_choices_repository.dart';
import '../features/lunch_box/data/lunch_pantry_repository.dart';

/// Lunch-box's V2 repositories — the pantry, budget mode and kid picks
/// (lunch-box ADR-0006 to ADR-0008) — in their own list, so the app-wide
/// graph changes by one line.
List<SingleChildWidget> lunchPlanningProviders() => [
  Provider<LunchPantryRepository>(
    create: (context) =>
        FirestoreLunchPantryRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<LunchBudgetRepository>(
    create: (context) =>
        FirestoreLunchBudgetRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<LunchChoicesRepository>(
    create: (context) =>
        FirestoreLunchChoicesRepository(context.read<FirebaseFirestore>()),
  ),
];
