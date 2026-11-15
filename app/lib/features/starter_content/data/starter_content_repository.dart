import '../../../shared/time/calendar_date.dart';
import '../../../shared/time/household_clock.dart';

/// Writes a new household's examples, and takes them away again (household
/// ADR-0010).
abstract interface class StarterContentRepository {
  /// Everything in one batch, as [memberId], dated from [today].
  Future<void> seed({
    required String householdId,
    required String memberId,
    required CalendarDate today,
  });

  /// Removes every example still there, changed or not, and nothing else. An
  /// admin's to do: the examples were written by whoever made the household.
  Future<void> clear({
    required String householdId,
    required HouseholdClock clock,
  });
}
