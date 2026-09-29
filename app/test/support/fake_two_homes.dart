import 'dart:async';

import 'package:nestprep/features/two_homes/data/two_homes_directory.dart';
import 'package:nestprep/features/two_homes/data/two_homes_repository.dart';
import 'package:nestprep/features/two_homes/model/change_request.dart';
import 'package:nestprep/features/two_homes/model/co_parent_home.dart';
import 'package:nestprep/features/two_homes/model/co_parent_link.dart';
import 'package:nestprep/features/two_homes/model/custody_schedule.dart';
import 'package:nestprep/features/two_homes/model/custody_side.dart';
import 'package:nestprep/features/two_homes/model/handover_note.dart';
import 'package:nestprep/features/two_homes/model/link_invite.dart';
import 'package:nestprep/shared/failure/app_failure.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import 'two_homes_model_fixtures.dart';

/// A household's copies of its links, driven by hand. Every stream is
/// broadcast, so a test can emit before or after a controller listens, and
/// [readsOpened] records which reads a controller asked for — the grant
/// decides that, and a read the rules would refuse is a listener that fails.
final class FakeTwoHomesRepository implements TwoHomesRepository {
  final links = StreamController<List<CoParentLink>>.broadcast();
  final link = StreamController<CoParentLink?>.broadcast();
  final handovers = StreamController<List<HandoverNote>>.broadcast();
  final handover = StreamController<HandoverNote?>.broadcast();
  final requests = StreamController<List<ChangeRequest>>.broadcast();
  final readsOpened = <String>[];

  Future<void> close() async {
    for (final controller in [links, link, handovers, handover, requests]) {
      await controller.close();
    }
  }

  @override
  Stream<List<CoParentLink>> watchLinks(String householdId) {
    readsOpened.add('links');
    return links.stream;
  }

  @override
  Stream<CoParentLink?> watchLink({
    required String householdId,
    required String linkId,
  }) {
    readsOpened.add('link');
    return link.stream;
  }

  @override
  Stream<List<HandoverNote>> watchHandovers({
    required String householdId,
    required String linkId,
    required CalendarDate from,
    required CalendarDate to,
  }) {
    readsOpened.add('handovers');
    return handovers.stream;
  }

  @override
  Stream<HandoverNote?> watchHandover({
    required String householdId,
    required String linkId,
    required CalendarDate date,
  }) {
    readsOpened.add('handover');
    return handover.stream;
  }

  @override
  Stream<List<ChangeRequest>> watchRequests({
    required String householdId,
    required String linkId,
  }) {
    readsOpened.add('requests');
    return requests.stream;
  }
}

/// The co-parenting callables, recorded rather than called. [failWith] makes
/// the next call refuse the way a Function would.
final class FakeTwoHomesDirectory implements TwoHomesDirectory {
  final calls = <(String, Map<String, Object?>)>[];
  AppFailure? failWith;

  LinkInviteCode invite = LinkInviteCode(
    code: 'ABCD2345',
    expiresAt: DateTime.utc(2026, 10, 6),
  );
  LinkInvitePreview preview = LinkInvitePreview(
    code: 'ABCD2345',
    childName: 'Sam',
    home: mumsHome,
    schedule: fixtureSchedule,
  );

  Future<void> _record(String name, Map<String, Object?> arguments) async {
    final failure = failWith;
    if (failure != null) throw failure;
    calls.add((name, arguments));
  }

  List<String> get names => [for (final (name, _) in calls) name];

  Map<String, Object?> lastOf(String name) =>
      calls.lastWhere((call) => call.$1 == name).$2;

  @override
  Future<LinkInviteCode> createInvite({
    required String householdId,
    required String childMemberId,
    required CoParentHome home,
    required CustodySchedule schedule,
  }) async {
    await _record('createInvite', {
      'childMemberId': childMemberId,
      'home': home,
      'schedule': schedule,
    });
    return invite;
  }

  @override
  Future<LinkInvitePreview> previewInvite(String code) async {
    await _record('previewInvite', {'code': code});
    return preview;
  }

  @override
  Future<String> acceptInvite({
    required String householdId,
    required String code,
    required CoParentHome home,
    String? childMemberId,
    String? newChildName,
  }) async {
    await _record('acceptInvite', {
      'code': code,
      'home': home,
      'childMemberId': childMemberId,
      'newChildName': newChildName,
    });
    return 'link-new';
  }

  @override
  Future<void> confirmLink({
    required String householdId,
    required String linkId,
    required bool accept,
  }) => _record('confirmLink', {'linkId': linkId, 'accept': accept});

  @override
  Future<void> endLink({required String householdId, required String linkId}) =>
      _record('endLink', {'linkId': linkId});

  @override
  Future<void> proposeSwap({
    required String householdId,
    required String linkId,
    required CalendarDate from,
    required CalendarDate to,
    required CustodySide toSide,
    String? note,
  }) => _record('proposeSwap', {
    'from': from,
    'to': to,
    'toSide': toSide,
    'note': note,
  });

  @override
  Future<void> proposeSchedule({
    required String householdId,
    required String linkId,
    required CustodySchedule schedule,
    String? note,
  }) => _record('proposeSchedule', {'schedule': schedule, 'note': note});

  @override
  Future<void> answerChange({
    required String householdId,
    required String linkId,
    required String requestId,
    required ChangeAnswer answer,
    String? note,
  }) => _record('answerChange', {
    'requestId': requestId,
    'answer': answer,
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
  }) => _record('saveHandover', {
    'date': date,
    'items': items,
    'medicine': medicine,
    'homework': homework,
    'clothes': clothes,
    'note': note,
  });
}
