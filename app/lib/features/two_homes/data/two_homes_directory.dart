import '../../../shared/time/calendar_date.dart';
import '../model/co_parent_home.dart';
import '../model/custody_schedule.dart';
import '../model/custody_side.dart';
import '../model/handover_note.dart';
import '../model/link_invite.dart';

/// How a request is answered.
enum ChangeAnswer { accept, decline, withdraw }

/// Everything that changes between two homes, each a Cloud Function because
/// it writes both homes' copies at once and no client is in both (household
/// ADR-0004). Every refusal arrives as an `AppFailure` —
/// `CoParentFailure` for the feature's own reasons, `HouseholdFailure` for
/// membership.
abstract interface class TwoHomesDirectory {
  Future<LinkInviteCode> createInvite({
    required String householdId,
    required String childMemberId,
    required CoParentHome home,
    required CustodySchedule schedule,
  });

  Future<LinkInvitePreview> previewInvite(String code);

  /// Accepts [code] for this household, with an existing kid profile or a
  /// new one called [newChildName]. Returns the new link's id.
  Future<String> acceptInvite({
    required String householdId,
    required String code,
    required CoParentHome home,
    String? childMemberId,
    String? newChildName,
  });

  Future<void> confirmLink({
    required String householdId,
    required String linkId,
    required bool accept,
  });

  Future<void> endLink({required String householdId, required String linkId});

  Future<void> proposeSwap({
    required String householdId,
    required String linkId,
    required CalendarDate from,
    required CalendarDate to,
    required CustodySide toSide,
    String? note,
  });

  Future<void> proposeSchedule({
    required String householdId,
    required String linkId,
    required CustodySchedule schedule,
    String? note,
  });

  Future<void> answerChange({
    required String householdId,
    required String linkId,
    required String requestId,
    required ChangeAnswer answer,
    String? note,
  });

  Future<void> saveHandover({
    required String householdId,
    required String linkId,
    required CalendarDate date,
    required List<HandoverItem> items,
    String? medicine,
    String? homework,
    String? clothes,
    String? note,
  });
}
