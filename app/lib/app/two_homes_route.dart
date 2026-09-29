import 'package:go_router/go_router.dart';

import '../shared/time/calendar_date.dart';
import 'household_route.dart';

/// Where two homes lives in the route table (household ADR-0004): pushed from
/// the household screen and the calendar, never a tab. Every id is in the
/// path, so a link and a handover are deep-linkable and back does the
/// obvious thing (`FE-17`).
abstract final class TwoHomesRoute {
  static const segment = 'two-homes';
  static const linkParameter = 'linkId';
  static const dateParameter = 'date';

  static const path = '${HouseholdRoute.path}/$segment';
  static const setupPath = '$path/new';
  static const joinPath = '$path/join';
  static const privacyPath = '$path/privacy';
  static const linkPath = '$path/links/:$linkParameter';
  static const schedulePath = '$linkPath/schedule';
  static const handoverPath = '$linkPath/handovers/:$dateParameter';

  static String pathFor(String householdId) =>
      '/households/$householdId/$segment';

  static String setupPathFor(String householdId) =>
      '${pathFor(householdId)}/new';

  static String joinPathFor(String householdId) =>
      '${pathFor(householdId)}/join';

  static String privacyPathFor(String householdId) =>
      '${pathFor(householdId)}/privacy';

  static String linkPathFor(String householdId, String linkId) =>
      '${pathFor(householdId)}/links/$linkId';

  static String schedulePathFor(String householdId, String linkId) =>
      '${linkPathFor(householdId, linkId)}/schedule';

  static String handoverPathFor(
    String householdId,
    String linkId,
    CalendarDate date,
  ) => '${linkPathFor(householdId, linkId)}/handovers/${date.iso}';

  static String linkIdFrom(GoRouterState state) =>
      _parameter(state, linkParameter);

  /// The handover's day. A path that is not a date is our bug, not a person's.
  static CalendarDate dateFrom(GoRouterState state) =>
      CalendarDate.parse(_parameter(state, dateParameter));

  static String _parameter(GoRouterState state, String name) {
    final value = state.pathParameters[name];
    if (value == null || value.isEmpty) {
      throw StateError('a two-homes route matched without a $name');
    }
    return value;
  }
}
