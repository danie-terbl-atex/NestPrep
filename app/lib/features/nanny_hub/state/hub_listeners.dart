import 'dart:async';

import '../../../shared/async/async_state.dart';
import '../../../shared/failure/app_failure.dart';
import '../data/nanny_hub_repository.dart';
import '../data/shift_repository.dart';
import '../model/child_card.dart';
import '../model/emergency_contact.dart';
import '../model/guide_spot.dart';
import '../model/home_sheet.dart';
import '../model/house_rule.dart';
import '../model/nanny_hub.dart';
import '../model/shift.dart';
import '../model/shift_checklist.dart';
import '../model/shift_summary.dart';

/// The hub's eight live reads, joined into one `NannyHub` once every one has
/// answered, so a screen never shows the guide before the emergency sheet
/// has arrived (foundation ADR-0006). Kept apart from the controller so that
/// file stays about what a screen can do (`ENG-05`).
final class HubListeners {
  HubListeners({
    required NannyHubRepository nannyHubRepository,
    required ShiftRepository shiftRepository,
    required this.householdId,
    required this.onChange,
  }) : _hub = nannyHubRepository,
       _shifts = shiftRepository;

  final NannyHubRepository _hub;
  final ShiftRepository _shifts;
  final String householdId;
  final void Function(AsyncState<NannyHub> state) onChange;

  final _subscriptions = <StreamSubscription<Object?>>[];
  List<ChildCard>? _cards;
  List<EmergencyContact>? _contacts;
  HomeSheet? _sheet;
  List<GuideSpot>? _guide;
  List<HouseRule>? _rules;
  List<ShiftChecklist>? _checklists;
  List<Shift>? _openShifts;
  List<ShiftSummary>? _summaries;

  void start() {
    _listen(_hub.watchCards(householdId), (value) => _cards = value);
    _listen(_hub.watchContacts(householdId), (value) => _contacts = value);
    _listen(_hub.watchSheet(householdId), (value) => _sheet = value);
    _listen(_hub.watchGuide(householdId), (value) => _guide = value);
    _listen(_hub.watchRules(householdId), (value) => _rules = value);
    _listen(_hub.watchChecklists(householdId), (value) => _checklists = value);
    _listen(
      _shifts.watchOpenShifts(householdId),
      (value) => _openShifts = value,
    );
    _listen(
      _shifts.watchSummaries(householdId),
      (value) => _summaries = value,
    );
  }

  void _listen<T>(Stream<T> stream, void Function(T value) keep) {
    _subscriptions.add(
      stream.listen((value) {
        keep(value);
        _publish();
      }, onError: _fail),
    );
  }

  void _publish() {
    final (cards, contacts, sheet, guide) = (_cards, _contacts, _sheet, _guide);
    final (rules, checklists, openShifts, summaries) = (
      _rules,
      _checklists,
      _openShifts,
      _summaries,
    );
    if (cards == null ||
        contacts == null ||
        sheet == null ||
        guide == null ||
        rules == null ||
        checklists == null ||
        openShifts == null ||
        summaries == null) {
      return;
    }
    onChange(
      AsyncData(
        NannyHub(
          cards: cards,
          contacts: contacts,
          sheet: sheet,
          guide: guide,
          rules: rules,
          checklists: checklists,
          openShifts: openShifts,
          summaries: summaries,
        ),
      ),
    );
  }

  void _fail(Object error) =>
      onChange(AsyncFailure(error is AppFailure ? error : UnknownFailure(error)));

  Future<void> stop() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _cards = null;
    _contacts = null;
    _sheet = null;
    _guide = null;
    _rules = null;
    _checklists = null;
    _openShifts = null;
    _summaries = null;
  }
}
