import 'package:nestprep/features/starter_content/data/starter_content_repository.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';
import 'package:nestprep/shared/time/household_clock.dart';

final class FakeStarterContentRepository implements StarterContentRepository {
  final seeded =
      <({String householdId, String memberId, CalendarDate today})>[];
  final cleared = <String>[];
  AppFailure? clearFailure;

  @override
  Future<void> seed({
    required String householdId,
    required String memberId,
    required CalendarDate today,
  }) async {
    seeded.add((householdId: householdId, memberId: memberId, today: today));
  }

  @override
  Future<void> clear({
    required String householdId,
    required HouseholdClock clock,
  }) async {
    final failure = clearFailure;
    if (failure != null) throw failure;
    cleared.add(householdId);
  }
}
