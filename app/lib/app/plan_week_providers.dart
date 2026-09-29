import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/plan_week/data/callable_week_planner.dart';
import '../features/plan_week/data/week_planner.dart';

/// *Plan my week*'s one outside dependency (lunch-box ADR-0011), in its own
/// list so the app-wide graph changes by one line.
List<SingleChildWidget> planWeekProviders() => [
  Provider<WeekPlanner>(
    create: (context) => CallableWeekPlanner(context.read<FirebaseFunctions>()),
  ),
];
