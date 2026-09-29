import 'package:cloud_functions/cloud_functions.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/time/calendar_date.dart';
import '../model/co_parent_home.dart';
import '../model/custody_schedule.dart';
import '../model/custody_side.dart';
import '../model/handover_note.dart';
import '../model/link_invite.dart';
import 'callable_json.dart';
import 'two_homes_directory.dart';
import 'two_homes_failure_mapper.dart';

/// The co-parenting callables (household ADR-0004). Every body is the one the
/// Function's zod schema parses, every optional text is sent as null rather
/// than left out, and every answer is parsed, never cast (`ENG-09`).
final class CallableTwoHomesDirectory implements TwoHomesDirectory {
  const CallableTwoHomesDirectory(this._functions);

  final FirebaseFunctions _functions;

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> body,
  ) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(body);
      return stringKeyed(result.data) ?? const {};
    } on FirebaseFunctionsException catch (error) {
      throw failureFromTwoHomesCallable(error);
    }
  }

  @override
  Future<LinkInviteCode> createInvite({
    required String householdId,
    required String childMemberId,
    required CoParentHome home,
    required CustodySchedule schedule,
  }) async {
    final result = await _call('createCoParentInvite', {
      'householdId': householdId,
      'childMemberId': childMemberId,
      'home': home.toJson(),
      'schedule': schedule.toJson(),
    });
    final code = result['code'];
    final expiresAt = DateTime.tryParse('${result['expiresAt']}');
    if (code is! String || expiresAt == null) {
      throw UnknownFailure(FormatException('createCoParentInvite', result));
    }
    return LinkInviteCode(code: code, expiresAt: expiresAt);
  }

  @override
  Future<LinkInvitePreview> previewInvite(String code) async {
    final result = await _call('previewCoParentInvite', {'code': code});
    final childName = result['childName'];
    final home = stringKeyed(result['home']);
    final schedule = stringKeyed(result['schedule']);
    if (childName is! String || home == null || schedule == null) {
      throw UnknownFailure(FormatException('previewCoParentInvite', result));
    }
    return parseOrFail(
      'previewCoParentInvite',
      () => LinkInvitePreview(
        code: code.trim().toUpperCase(),
        childName: childName,
        home: CoParentHome.fromJson(home),
        schedule: CustodySchedule.fromJson(schedule),
      ),
    );
  }

  @override
  Future<String> acceptInvite({
    required String householdId,
    required String code,
    required CoParentHome home,
    String? childMemberId,
    String? newChildName,
  }) async {
    final result = await _call('acceptCoParentInvite', {
      'householdId': householdId,
      'code': code,
      'childMemberId': childMemberId,
      'newChildName': newChildName,
      'home': home.toJson(),
    });
    final linkId = result['linkId'];
    if (linkId is! String) {
      throw UnknownFailure(FormatException('acceptCoParentInvite', result));
    }
    return linkId;
  }

  @override
  Future<void> confirmLink({
    required String householdId,
    required String linkId,
    required bool accept,
  }) => _call('confirmCoParentLink', {
    'householdId': householdId,
    'linkId': linkId,
    'accept': accept,
  });

  @override
  Future<void> endLink({required String householdId, required String linkId}) =>
      _call('endCoParentLink', {'householdId': householdId, 'linkId': linkId});

  @override
  Future<void> proposeSwap({
    required String householdId,
    required String linkId,
    required CalendarDate from,
    required CalendarDate to,
    required CustodySide toSide,
    String? note,
  }) => _call('proposeCoParentChange', {
    'householdId': householdId,
    'linkId': linkId,
    'change': {
      'kind': 'swap',
      'from': from.iso,
      'to': to.iso,
      'toSide': toSide.name,
    },
    'note': note,
  });

  @override
  Future<void> proposeSchedule({
    required String householdId,
    required String linkId,
    required CustodySchedule schedule,
    String? note,
  }) => _call('proposeCoParentChange', {
    'householdId': householdId,
    'linkId': linkId,
    'change': {'kind': 'schedule', 'schedule': schedule.toJson()},
    'note': note,
  });

  @override
  Future<void> answerChange({
    required String householdId,
    required String linkId,
    required String requestId,
    required ChangeAnswer answer,
    String? note,
  }) => _call('answerCoParentChange', {
    'householdId': householdId,
    'linkId': linkId,
    'requestId': requestId,
    'answer': answer.name,
    'note': note,
  });

  @override
  Future<void> saveHandover({
    required String householdId,
    required String linkId,
    required CalendarDate date,
    required List<HandoverItem> items,
    String? medicine,
    String? homework,
    String? clothes,
    String? note,
  }) => _call('saveCoParentHandover', {
    'householdId': householdId,
    'linkId': linkId,
    'date': date.iso,
    'items': [for (final item in items) item.toJson()],
    'medicine': medicine,
    'homework': homework,
    'clothes': clothes,
    'note': note,
  });
}
