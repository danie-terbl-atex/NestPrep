import '../../../shared/time/calendar_date.dart';
import '../model/trail.dart';

abstract interface class TrailRepository {
  /// [day] is a household-local date; [from] and [to] are its bounds as
  /// instants, which only the household's clock can work out.
  Future<TrailDay> loadDay({
    required String householdId,
    required String memberId,
    required CalendarDate day,
    required DateTime from,
    required DateTime to,
  });

  Future<void> clearHistory({
    required String householdId,
    required String memberId,
  });

  static const retention = Duration(days: 30);
  static const eventLimit = 200;
}
