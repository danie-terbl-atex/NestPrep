import 'package:go_router/go_router.dart';

import '../features/home_care/model/home_care_board.dart';
import 'household_route.dart';

/// Where home care lives in the route table (home-care ADR-0001): the job
/// list with its pile in the query, a new job, the rooms, the products, and
/// one job with its steps and its review. Every id is in the path, so each
/// screen is deep-linkable and back does the obvious thing (`FE-17`).
abstract final class HomeCareRoute {
  static const segment = 'home-care';
  static const jobParameter = 'jobId';
  static const pileQuery = 'pile';

  static const path = '${HouseholdRoute.path}/$segment';
  static const newJobPath = '$path/new';
  static const roomsPath = '$path/rooms';
  static const productsPath = '$path/products';
  static const jobPath = '$path/jobs/:$jobParameter';
  static const stepsPath = '$jobPath/steps';
  static const reviewPath = '$jobPath/review';

  static String pathFor(String householdId, {JobPile? pile}) {
    final base = '/households/$householdId/$segment';
    return pile == null || pile == JobPile.toDo
        ? base
        : '$base?$pileQuery=${pile.name}';
  }

  static String newJobPathFor(String householdId) =>
      '${pathFor(householdId)}/new';

  static String roomsPathFor(String householdId) =>
      '${pathFor(householdId)}/rooms';

  static String productsPathFor(String householdId) =>
      '${pathFor(householdId)}/products';

  static String jobPathFor(String householdId, String jobId) =>
      '${pathFor(householdId)}/jobs/$jobId';

  static String stepsPathFor(String householdId, String jobId) =>
      '${jobPathFor(householdId, jobId)}/steps';

  static String reviewPathFor(String householdId, String jobId) =>
      '${jobPathFor(householdId, jobId)}/review';

  /// The pile the list opens on; anything unrecognised is the to-do pile.
  static JobPile pileFrom(GoRouterState state) {
    final name = state.uri.queryParameters[pileQuery];
    return JobPile.values.where((pile) => pile.name == name).firstOrNull ??
        JobPile.toDo;
  }

  /// The job this route was matched with. Its absence would mean the route
  /// table and this helper disagree, which is our bug and not a person's.
  static String jobIdFrom(GoRouterState state) {
    final id = state.pathParameters[jobParameter];
    if (id == null || id.isEmpty) {
      throw StateError('a job route matched without a $jobParameter');
    }
    return id;
  }
}
