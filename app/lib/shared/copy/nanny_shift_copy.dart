import '../../features/nanny_hub/model/handover_kind.dart';
import '../../features/nanny_hub/model/handover_mood.dart';

/// Shift mode's words and a finished shift's summary (`FE-19`) — the half of
/// the nanny hub a carer reads with a child on one hip, kept beside
/// `NannyCopy` so neither file grows past what anybody can read (`ENG-05`).
abstract final class NannyShiftCopy {
  // Shift mode.
  static const shiftTitle = 'On shift';
  static String shiftStarted(String time) => 'Started at $time';
  static const logSomething = 'What happened?';
  static const checklistNow = 'Checklist';
  static const logSoFar = 'The log so far';
  static const logEmpty =
      'Nothing logged yet. Tap a button above whenever something happens — '
      'it only takes a second.';
  static const endShift = 'End shift';
  static const endShiftTitle = 'End your shift?';
  static const endShiftBody =
      'The parents get a summary of everything you logged. You cannot add to '
      'this shift afterwards.';
  static const closingNote = 'A last word for the parents (optional)';
  static const closingNoteHint = 'Asleep by eight, a lovely evening.';
  static const shiftEndedTitle = 'This shift has ended';
  static const shiftEndedBody = 'Its summary is ready for the parents.';
  static const seeSummary = 'See the summary';
  static const shiftGoneTitle = 'This shift is not here';
  static const shiftGoneBody = 'It may have been removed. Go back to the hub.';
  static const openEmergency = 'Emergency numbers';
  static String ticked(int done, int total) => '$done of $total done';

  // Logging an entry.
  static String logTitle(HandoverKind kind) => switch (kind) {
    HandoverKind.meal => 'Log a meal',
    HandoverKind.nap => 'Log a nap',
    HandoverKind.nappy => 'Log a nappy',
    HandoverKind.mood => 'How are they?',
    HandoverKind.incident => 'Log an incident',
    HandoverKind.medicine => 'Log medicine given',
    HandoverKind.note => 'Add a note',
  };
  static String kindName(HandoverKind kind) => switch (kind) {
    HandoverKind.meal => 'Meal',
    HandoverKind.nap => 'Nap',
    HandoverKind.nappy => 'Nappy',
    HandoverKind.mood => 'Mood',
    HandoverKind.incident => 'Incident',
    HandoverKind.medicine => 'Medicine',
    HandoverKind.note => 'Note',
  };
  static String noteHint(HandoverKind kind) => switch (kind) {
    HandoverKind.meal => 'Ate all the pasta, left the peas',
    HandoverKind.nap => 'Slept 13:00 to 14:30',
    HandoverKind.nappy => 'Wet, changed at 15:10',
    HandoverKind.mood => 'Anything else about how they are',
    HandoverKind.incident => 'What happened, and what you did',
    HandoverKind.medicine => 'What, how much, and when',
    HandoverKind.note => 'Anything the parents should know',
  };
  static String moodName(HandoverMood mood) => switch (mood) {
    HandoverMood.happy => 'Happy',
    HandoverMood.calm => 'Calm',
    HandoverMood.tired => 'Tired',
    HandoverMood.upset => 'Upset',
    HandoverMood.unwell => 'Unwell',
  };
  static const whoFor = 'Which children';
  static const whenLabel = 'When';
  static const now = 'Now';
  static const note = 'Note';
  static const entryNeedsSomething = 'Add a note, a mood or a photo.';
  static const logIt = 'Log it';
  static const removeEntryConfirm = 'Remove this from the log?';
  static const withPhoto = 'With a photo';
  static const incidentWarning =
      'If a child is hurt or unwell, call for help first — the emergency '
      'numbers are one tap away.';

  // A summary.
  static const summaryTitle = 'Handover';
  static String summaryHeadline(String carer) => '$carer’s shift';
  static String summaryWhen(String day, String from, String to) =>
      '$day, $from – $to';
  static String summaryCount(HandoverKind kind, int count) =>
      '${kindName(kind)} · $count';
  static const summaryIncident =
      'There was an incident this shift. Read it below.';
  static const summaryClosingNote = 'From the carer';
  static const summaryChecklist = 'Checklists';
  static const summaryMoments = 'What happened';
  static const summaryNothingLogged = 'Nothing was logged this shift.';
  static String summaryTrimmed(int count) =>
      'The first $count moments are shown; the counts include every one.';
  static String summaryPhotos(int count) =>
      count == 1 ? '1 photo' : '$count photos';
  static const summaryGoneTitle = 'This summary is not here';
  static const summaryGoneBody =
      'It may still be being written. Go back and open it again.';
  static const summaryPending = 'Just now';
}
