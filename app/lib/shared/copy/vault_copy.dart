import '../../features/documents/model/expiry_schedule.dart';

/// The words of documents phase 2 — the personal vaults, scanning, search and
/// expiry (documents ADR-0002 to ADR-0005).
///
/// Its own file beside `AppCopy` rather than inside it, so a feature built in
/// parallel with others does not rewrite the one file every feature shares.
/// Same rule as `AppCopy` (`FE-19`): screens read from here, and
/// `one_home_for_copy_test.dart` fails on a word nothing says.
abstract final class VaultCopy {
  // ---- the way in, from Documents ----
  static const entryTitle = 'Personal vaults';
  static const entryBody =
      'Each person\'s ID, passport and medical cards, behind your phone\'s '
      'lock.';
  static const entryLocked = 'Locked';
  static const entryUnlocked = 'Open';
  static const householdSection = 'Household folders';

  // ---- the lock (documents ADR-0003) ----
  static const lockedTitle = 'The vaults are locked';
  static const lockedBody =
      'Passports, IDs and medical cards live here. Unlock with your '
      'fingerprint, your face or your phone\'s PIN.';
  static const unlock = 'Unlock';
  static const unlocking = 'Waiting for your phone';
  static const unlockReason = 'Unlock the family vaults';
  static const lockNow = 'Lock the vaults';
  static const noScreenLock =
      'This phone has no screen lock. Set a PIN, pattern or fingerprint in '
      'your phone\'s settings — the vaults only open behind one.';
  static const lockedOut =
      'Too many tries. Wait a moment, then unlock with your phone\'s PIN.';
  static const lockUnavailable =
      'This phone could not ask who you are. Try again.';

  // ---- the vaults ----
  static const homeTitle = 'Personal vaults';
  static const homeEmptyTitle = 'No vaults open to you';
  static const homeEmptyBody =
      'Your own vault appears once you have joined as a person in this '
      'household. Somebody else\'s appears when they share it with you.';
  static const peopleSection = 'People';
  static const viewLog = 'Who opened what';

  static String vaultOf(String name) => '$name\'s vault';

  static const personEmptyTitle = 'Nothing in this vault yet';
  static const personEmptyBody =
      'Scan an ID card front and back, or add a PDF you already have.';
  static const personEmptyBodyReadOnly = 'Nothing has been filed here yet.';
  static const readOnlyNote =
      'Shared with you to read. Only its owner or an '
      'admin can change it.';
  static const scan = 'Scan';
  static const addFile = 'Choose a file';
  static String pageOf(int page, int count) => 'Page $page of $count';

  static const opensAreLogged =
      'Opening a document here is written in the vault\'s log.';

  // ---- sharing a vault (documents ADR-0002) ----
  static const accessTitle = 'Who can see this vault';
  static const accessBody =
      'The family always can. Anybody else you switch on here can read this '
      'vault, but not change it.';
  static const accessNobodyElse =
      'Nobody else in the household has joined yet.';
  static const accessAlways = 'Family — always';

  static String sharedWith(int count) => switch (count) {
    0 => 'Only its owner and the family',
    1 => 'Shared with 1 more person',
    _ => 'Shared with $count more people',
  };

  // ---- scanning (documents ADR-0004) ----
  static const reviewTitle = 'Check the scan';
  static const reviewBody =
      'Make sure every word is sharp. The sides are kept together as one PDF.';
  static const nameHint = 'Passport';
  static const saveToVault = 'Save to the vault';
  static const saveToFolder = 'Add to the folder';
  static const preparing = 'Preparing the scan';
  static const addOptionsTitle = 'Add a document';

  static String side(int index) => switch (index) {
    0 => 'Front',
    1 => 'Back',
    _ => 'Side ${index + 1}',
  };

  static String scanName(String date) => 'Scan $date';

  // ---- details: tags and expiry (documents ADR-0005) ----
  static const detailsTitle = 'Edit details';
  static const tagsLabel = 'Tags';
  static const tagsHint = 'ID, school, medical';
  static const addTag = 'Add tag';
  static const tagsLimit = 'Up to eight tags, each up to 24 letters.';
  static const expiryLabel = 'Expires';
  static const addExpiry = 'Add an expiry date';
  static const removeExpiry = 'Remove the date';

  static String removeTag(String tag) => 'Remove $tag';

  /// The reminder schedule, in words, from the one list both sides of the
  /// wire read — so this sentence cannot drift from what is sent.
  static String get remindersNote {
    final before = ExpirySchedule.reminderDaysBefore.where((d) => d > 0);
    final days = before.map((d) => '$d').toList();
    final list = days.length < 2
        ? days.join()
        : '${days.sublist(0, days.length - 1).join(', ')} and ${days.last}';
    return 'You will be reminded $list days before, and on the day.';
  }

  // ---- expiry badges ----
  static const expired = 'Expired';
  static const expiresToday = 'Expires today';

  static String expiresIn(int days) =>
      days == 1 ? 'Expires tomorrow' : 'Expires in $days days';

  static String expiresOn(String date) => 'Expires $date';

  static const expiringTitle = 'Expiring soon';
  static const expiringSeeAll = 'See all';

  // ---- search ----
  static const searchTitle = 'Find a document';
  static const searchHint = 'Passport, school, a name…';
  static const searchEveryone = 'Everyone';
  static const searchHousehold = 'Household';
  static const searchExpiring = 'Expiring soon';
  static const searchNoResultsTitle = 'Nothing matches';
  static const searchNoResultsBody = 'Try fewer words, or clear the filters.';
  static const searchClearFilters = 'Clear filters';
  static const searchLockedNote =
      'The personal vaults are locked, so only household papers are searched.';

  static String resultCount(int count) =>
      count == 1 ? '1 document' : '$count documents';

  // ---- the view log (documents ADR-0003) ----
  static const logTitle = 'Who opened what';
  static const logBody =
      'Every time somebody opens a vault document, the server writes it here. '
      'Nobody can change it.';
  static const logEmptyTitle = 'Nothing opened yet';
  static const logEmptyBody =
      'When somebody opens a document in a vault, it shows here.';
  static const logSomebody = 'Somebody';
  static const logThroughLink = 'Somebody with a shared link';

  static String logLine(String viewer, String vault) =>
      '$viewer opened it · $vault';
}
