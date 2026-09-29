import '../../features/nanny_hub/model/contact_kind.dart';
import '../../features/nanny_hub/model/emergency_number.dart';
import '../../features/nanny_hub/model/shift_moment.dart';
import '../failure/app_failure.dart';

/// Every word the nanny hub says (`FE-19`), in a file of its own exported from
/// `app_copy.dart`, so a feature this size does not grow the one copy file and
/// parallel features do not all edit the same lines. The tone is the carer's:
/// calm, short, and readable with a child on one hip.
abstract final class NannyCopy {
  static const title = 'Nanny hub';
  static const openFromHousehold = 'Nanny hub';
  static const openFromHouseholdBody =
      'Everything a carer needs for a shift: the children, emergency numbers, '
      'the house guide and a handover log.';

  // The hub's home.
  static const readyTitle = 'Ready when you are';
  static const readyBody =
      'Start your shift when you arrive. Log meals, naps and anything worth '
      'telling, and the parents get a summary when you finish.';
  static const startMyShift = 'Start my shift';
  static const startShiftFor = 'Start a shift for…';
  static const startShiftForTitle = 'Who is looking after the children?';
  static const onShiftTitle = 'You are on shift';
  static const openShiftMode = 'Open shift mode';
  static const nobodyOnShift = 'Nobody is on shift';
  static const nobodyOnShiftBody =
      'A carer starts their shift from here when they arrive.';
  static const viewShift = 'See the shift';
  static String onShiftSince(String name, String time) =>
      '$name is on shift since $time';
  static String youSince(String time) => 'Since $time';
  static const latestHandover = 'Latest handover';
  static const children = 'Children';
  static const noChildrenTitle = 'No children here yet';
  static const noChildrenBody =
      'Add each child on the household screen as a kid, and their card '
      'appears here.';
  static const forTheShift = 'For the shift';
  static const pastShifts = 'Past shifts';
  static const noPastShifts =
      'When a shift ends, its summary is kept here for the parents.';
  static const viewOnlyNote =
      'You can read the hub. A parent can let you log shifts too.';

  // The four places.
  static const emergency = 'Emergency';
  static String emergencyBody(int contacts) => contacts == 0
      ? 'Emergency numbers and the address'
      : contacts == 1
      ? '1 contact, emergency numbers and the address'
      : '$contacts contacts, emergency numbers and the address';
  static const houseGuide = 'House guide';
  static String houseGuideBody(int spots) => spots == 0
      ? 'Photos of where things are'
      : spots == 1
      ? '1 place'
      : '$spots places';
  static const houseRules = 'House rules';
  static String houseRulesBody(int rules) => rules == 0
      ? 'What goes in this house'
      : rules == 1
      ? '1 rule'
      : '$rules rules';
  static const checklists = 'Shift checklists';
  static String checklistsBody(int items) => items == 0
      ? 'Arrival, after school, dinner, bedtime, leaving'
      : items == 1
      ? '1 thing to do'
      : '$items things to do';

  // A child's card.
  static const allergies = 'Allergies';
  static const noAllergies = 'No allergies recorded';
  static const allergiesHiddenTitle = 'Allergies are not shared with you';
  static const allergiesHiddenBody =
      'Ask a parent before giving this child any food.';
  static const medication = 'Medication';
  static const noMedication = 'No medication recorded';
  static const medicationHiddenTitle = 'Medication is private';
  static const medicationHiddenBody =
      'A parent can share it with you from the household screen.';
  static const routine = 'Routine';
  static const noRoutine = 'No routine written down yet';
  static const editRoutine = 'Edit routine';
  static const anyTime = 'Any time';
  static const likesAndDislikes = 'Likes and dislikes';
  static const likes = 'Likes';
  static const dislikes = 'Dislikes';
  static const noLikes = 'Nothing recorded yet';
  static const comfort = 'Comfort items';
  static const noComfort = 'None written down yet';
  static const editComfort = 'Edit comfort items';
  static const comfortHint = 'Blue bunny, the yellow blanket…';
  static const settling = 'How to settle them';
  static const noSettling = 'Nothing written down yet';
  static const editSettling = 'Edit how to settle them';
  static const settlingHint = 'Two songs, the night light, a back rub…';
  static const goodToKnow = 'Good to know';
  static const goodToKnowHint = 'Scared of the dark, calls water "wawa"…';
  static const childGoneTitle = 'This child is no longer in the household';
  static const childGoneBody = 'Go back to see who is here now.';
  static const addPhoto = 'Add a photo';
  static const changePhoto = 'Change photo';
  static const removePhoto = 'Remove photo';
  static const photoOfChild = 'Photo of the child';

  // Editing a routine and a list.
  static const routineStep = 'What happens';
  static const routineStepHint = 'Bath, snack, homework…';
  static const routineTime = 'Time';
  static const routineNote = 'How (optional)';
  static const addStep = 'Add a step';
  static const removeStep = 'Remove this step';
  static const pickTime = 'Pick a time';
  static const clearTime = 'No set time';
  static const addItem = 'Add';
  static const removeItem = 'Remove';
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const delete = 'Delete';
  static String limitReached(int limit) =>
      'That is the most there can be ($limit).';

  // The emergency sheet.
  static const emergencyTitle = 'Emergency';
  static const emergencyIntro =
      'In an emergency, call first. Then call a parent.';
  static String callNumber(String name, String digits) => '$name · $digits';
  static String emergencyNumberName(EmergencyNumber number) => switch (number) {
    EmergencyNumber.police => 'Police',
    EmergencyNumber.ambulance => 'Ambulance and fire',
    EmergencyNumber.mobile => 'Emergency from a mobile',
  };
  static const ourAddress = 'Our address';
  static const noAddress = 'No address written down yet';
  static const addressHint = 'The address to tell an ambulance';
  static const medicalAid = 'Medical aid';
  static const noMedicalAid = 'No medical aid written down yet';
  static const medicalAidScheme = 'Scheme';
  static const medicalAidPlan = 'Plan';
  static const medicalAidNumber = 'Membership number';
  static const editHomeDetails = 'Edit address and medical aid';
  static const contacts = 'People to call';
  static const noContacts =
      'No numbers yet. Add the parents first, then a backup adult nearby.';
  static const addContact = 'Add a contact';
  static const editContact = 'Edit contact';
  static const contactName = 'Name';
  static const contactPhone = 'Phone number';
  static const contactPhoneHint = '082 555 0123';
  static const contactNote = 'Note (optional)';
  static const contactNoteHint = 'Lives two streets away';
  static const contactKindLabel = 'Who they are';
  static const removeContactConfirm = 'Remove this contact?';
  static const phoneNotValid = 'Use only digits, spaces and a leading +.';
  static String call(String name) => 'Call $name';
  static String contactKindName(ContactKind kind) => switch (kind) {
    ContactKind.parent => 'Parent',
    ContactKind.backup => 'Backup adult',
    ContactKind.doctor => 'Doctor',
    ContactKind.hospital => 'Hospital',
    ContactKind.other => 'Other',
  };

  // The house guide.
  static const guideEmptyTitle = 'Nothing in the guide yet';
  static const guideEmptyBody =
      'Take a photo of where the nappies, spare clothes and first-aid kit '
      'are, so nobody has to phone and ask.';
  static const guideEmptyCarer = 'A parent adds places here.';
  static const addSpot = 'Add a place';
  static const editSpot = 'Edit place';
  static const spotTitle = 'What is here';
  static const spotTitleHint = 'Spare nappies';
  static const spotNote = 'Where exactly (optional)';
  static const spotNoteHint = 'Top shelf of the linen cupboard';
  static const removeSpotConfirm = 'Remove this place?';
  static const takePhoto = 'Take a photo';
  static const choosePhoto = 'Choose a photo';
  static const photoLoading = 'Loading photo';
  static const photoFailed = 'The photo did not load';

  // House rules.
  static const rulesEmptyTitle = 'No house rules yet';
  static const rulesEmptyBody =
      'Screen time, sweets, bedtime, visitors — whatever a carer should know '
      'this house decides.';
  static const rulesEmptyCarer = 'A parent adds the house rules here.';
  static const addRule = 'Add a rule';
  static const editRule = 'Edit rule';
  static const ruleText = 'The rule';
  static const ruleTextHint = 'No screens after six';
  static const removeRuleConfirm = 'Remove this rule?';

  // Checklists.
  static const checklistsIntro =
      'What to do at each part of a shift. The carer ticks them off during '
      'the shift; the list itself stays as you wrote it.';
  static const noChecklistItems = 'Nothing to do here';
  static String editChecklist(ShiftMoment moment) =>
      'Edit ${momentName(moment).toLowerCase()}';
  static const checklistItemHint = 'Unpack school bags';
  static String momentName(ShiftMoment moment) => switch (moment) {
    ShiftMoment.arrival => 'Arrival',
    ShiftMoment.afterSchool => 'After school',
    ShiftMoment.dinner => 'Dinner',
    ShiftMoment.bedtime => 'Bath and bedtime',
    ShiftMoment.beforeLeaving => 'Before leaving',
  };

  static String problem(NannyHubProblem problem) => switch (problem) {
    NannyHubProblem.hubNotShared =>
      'The nanny hub is not yours to change. Ask a parent.',
    NannyHubProblem.shiftNotFound => 'That shift is no longer there.',
    NannyHubProblem.shiftAlreadyEnded =>
      'That shift has already ended. Its summary is in the hub.',
    NannyHubProblem.notYourShift =>
      'That is somebody else’s shift. Only they, or a parent, can end it.',
    NannyHubProblem.photoUnreadable =>
      'That photo could not be read. Try another one.',
    NannyHubProblem.photoTooLarge =>
      'That photo is too big to keep, even made smaller. Try another one.',
    NannyHubProblem.cameraUnavailable =>
      'The camera or your photos would not open. Check NestPrep may use them '
          'in your phone settings.',
    NannyHubProblem.cannotCall =>
      'This phone would not place the call. Dial the number yourself.',
    NannyHubProblem.notACarer =>
      'Only a carer can be kept to their booked shifts.',
    NannyHubProblem.cannotSaveOffline =>
      'This phone would not keep a copy for offline. It may be short of '
          'space.',
    NannyHubProblem.codesClosed =>
      'The house codes open 15 minutes before your booked shift.',
  };
}
