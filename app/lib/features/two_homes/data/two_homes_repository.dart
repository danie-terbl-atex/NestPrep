import '../../../shared/time/calendar_date.dart';
import '../model/change_request.dart';
import '../model/co_parent_link.dart';
import '../model/handover_note.dart';

/// Reads this household's own copies of its links with other homes
/// (household ADR-0004). There is no write here at all: every change between
/// two homes is a callable, in `TwoHomesDirectory`, because no client is in
/// both households.
abstract interface class TwoHomesRepository {
  /// Every link this household has — open ones and the history.
  Stream<List<CoParentLink>> watchLinks(String householdId);

  /// One link, or null once it is gone.
  Stream<CoParentLink?> watchLink({
    required String householdId,
    required String linkId,
  });

  /// The handovers written up between [from] and [to], by date.
  Stream<List<HandoverNote>> watchHandovers({
    required String householdId,
    required String linkId,
    required CalendarDate from,
    required CalendarDate to,
  });

  /// One handover, or null while nobody has written it.
  Stream<HandoverNote?> watchHandover({
    required String householdId,
    required String linkId,
    required CalendarDate date,
  });

  /// The link's requests, newest first.
  Stream<List<ChangeRequest>> watchRequests({
    required String householdId,
    required String linkId,
  });
}
