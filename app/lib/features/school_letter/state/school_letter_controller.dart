import 'package:flutter/foundation.dart';

import '../../../shared/failure/app_failure.dart';
import '../../calendar/data/calendar_repository.dart';
import '../data/letter_picker.dart';
import '../data/school_letter_reader.dart';
import '../model/letter_file.dart';
import '../model/letter_proposal.dart';
import '../model/review_item.dart';

/// Where the snap-a-letter screen is (calendar ADR-0005).
enum LetterStep {
  /// Nothing picked yet — or a read that failed, with its failure beside it.
  choosing,

  /// The letter is with the model.
  reading,

  /// The proposals are on screen to tick, edit and confirm. An empty list is
  /// this step too, and says so in place.
  review,

  /// The ticked events are being added.
  saving,

  /// They were; the screen says how many and offers the week.
  done,
}

/// The snap-a-letter screen's controller: picks a letter, has it read, holds
/// the review list, and adds **only** what the parent ticked and confirmed.
///
/// The review list is this screen's own state, not server state: the
/// proposals exist nowhere but here until they are saved as ordinary events
/// through the calendar's repository and the calendar's rules (`FE-07`).
final class SchoolLetterController extends ChangeNotifier {
  SchoolLetterController({
    required SchoolLetterReader schoolLetterReader,
    required LetterPicker letterPicker,
    required CalendarRepository calendarRepository,
    required this.householdId,
    required this.memberId,
  }) : _reader = schoolLetterReader,
       _picker = letterPicker,
       _calendar = calendarRepository;

  final SchoolLetterReader _reader;
  final LetterPicker _picker;
  final CalendarRepository _calendar;
  final String householdId;

  /// Who is adding the events — their `createdBy`.
  final String memberId;

  LetterStep _step = LetterStep.choosing;
  AppFailure? _failure;
  LetterFile? _letter;
  List<ReviewItem> _items = const [];
  int? _callsLeft;
  int _added = 0;

  LetterStep get step => _step;

  /// What went wrong last, in the step it went wrong in.
  AppFailure? get failure => _failure;
  List<ReviewItem> get items => _items;

  /// AI calls left this month, once a read has said.
  int? get callsLeft => _callsLeft;

  /// How many events the last confirm added.
  int get added => _added;

  int get tickedCount => _items.where((item) => item.isTicked).length;

  /// Whether the last letter can be sent again as it is — after a failure
  /// that a second try might fix.
  bool get canRetry => _letter != null && _step == LetterStep.choosing;

  Future<void> pick(LetterSource source) async {
    if (_step == LetterStep.reading || _step == LetterStep.saving) return;
    final LetterFile? letter;
    try {
      letter = await _picker.pick(source);
    } on AppFailure catch (failure) {
      _moveTo(LetterStep.choosing, failure: failure);
      return;
    }
    if (letter == null) return;
    await _read(letter);
  }

  Future<void> retry() async {
    final letter = _letter;
    if (letter != null) await _read(letter);
  }

  Future<void> _read(LetterFile letter) async {
    _letter = letter;
    _moveTo(LetterStep.reading);
    try {
      final reading = await _reader.read(
        householdId: householdId,
        letter: letter,
      );
      _callsLeft = reading.callsLeft;
      var key = 0;
      _items = [
        for (final proposal in reading.proposals)
          ReviewItem(key: key++, proposal: proposal),
      ];
      _moveTo(LetterStep.review);
    } on AppFailure catch (failure) {
      _moveTo(LetterStep.choosing, failure: failure);
    }
  }

  void toggle(int key) => _update(key, (item) => item.ticked(!item.isTicked));

  /// The parent's own version of a proposal, from the event sheet. Editing it
  /// ticks it: nobody edits an event they do not mean to add.
  void replace(int key, LetterProposal edited) =>
      _update(key, (item) => item.withProposal(edited).ticked(true));

  /// Adds every ticked proposal as an ordinary event. Each is one document of
  /// its own, so an interruption leaves some added and some not — and the
  /// ones that were not stay on the list, ticked, with the failure said, so
  /// confirming again finishes the job without adding anything twice
  /// (`BE-07`).
  Future<void> confirm() async {
    if (_step != LetterStep.review || tickedCount == 0) return;
    _moveTo(LetterStep.saving);
    final remaining = <ReviewItem>[];
    var added = 0;
    for (final item in _items) {
      if (!item.isTicked) {
        remaining.add(item);
        continue;
      }
      try {
        await _save(item.proposal);
        added += 1;
      } on AppFailure {
        remaining.add(item);
      }
    }
    _added = added;
    final failed = remaining.any((item) => item.isTicked);
    _items = failed ? remaining : const [];
    _moveTo(
      failed ? LetterStep.review : LetterStep.done,
      failure: failed
          ? const SchoolLetterFailure(SchoolLetterProblem.someNotAdded)
          : null,
    );
  }

  /// Back to the start, for another letter.
  void startOver() {
    _letter = null;
    _items = const [];
    _added = 0;
    _moveTo(LetterStep.choosing);
  }

  void dismissFailure() {
    if (_failure == null) return;
    _failure = null;
    notifyListeners();
  }

  Future<void> _save(LetterProposal proposal) => _calendar.saveEvent(
    householdId: householdId,
    title: proposal.title,
    note: proposal.note,
    date: proposal.date,
    startMinute: proposal.startMinute,
    endMinute: proposal.endMinute,
    recurrence: proposal.recurrence,
    memberIds: proposal.memberIds,
    createdBy: memberId,
  );

  void _update(int key, ReviewItem Function(ReviewItem item) change) {
    if (_step != LetterStep.review) return;
    _items = [for (final item in _items) item.key == key ? change(item) : item];
    notifyListeners();
  }

  void _moveTo(LetterStep step, {AppFailure? failure}) {
    _step = step;
    _failure = failure;
    notifyListeners();
  }
}
