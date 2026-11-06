import '../../features/photo_frames/model/frame_photo.dart';
import '../failure/app_failure.dart';

abstract final class PhotoFrameCopy {
  static const title = 'Photo frames';
  static const openFromHouseholdBody = 'Put the family’s day on the wall';

  // ---- the frames ----
  static const intro =
      'A frame on the wall shows the bits of the day you choose. Tap one to '
      'change what it shows.';
  static const emptyTitle = 'No frames yet';
  static const emptyBody =
      'Open nestprep Home on the frame and it shows a code. Scan it here and '
      'the family’s day is on the wall.';
  static const link = 'Link a frame';
  static const showsNothing = 'Nothing chosen to show';
  static String helperDay(String name) => '$name’s day';
  static String seen(String ago) => 'Seen ${ago.toLowerCase()}';
  static String lastSeen(String moment) => 'Last seen $moment';
  static const waitingToHear = 'Waiting to hear from it';
  static const notHeardSinceLinked = 'Not heard from since it was linked';

  // ---- linking one: the code ----
  static const scanBody = 'Point your camera at the code on the frame.';
  static const typeInstead = 'Type the code instead';
  static const scanInstead = 'Scan the code instead';
  static const typeBody = 'Type the six letters under the code on the frame.';
  static const codeFieldLabel = 'The frame’s six-letter code';
  static const next = 'Next';
  static const notAFrameCode =
      'That isn’t a NestPrep frame code. Scan the one on the frame’s screen.';
  static const cameraRefused =
      'NestPrep needs the camera to scan. Allow it in your phone settings, or '
      'type the code.';
  static const cameraUnavailable =
      'The camera isn’t free just now. Type the code instead.';
  static String codeFound(String code) => 'Frame $code';
  static const differentCode = 'Use a different code';

  // ---- linking one: what it shows ----
  static const nameLabel = 'Name';
  static const defaultName = 'Kitchen frame';
  static const showsTitle = 'What it shows';
  static const calendar = 'Calendar';
  static const calendarBody = 'Today and the next two days, notes included';
  static const addEvents = 'Add events from the frame';
  static const addEventsBody =
      'Anyone at the frame can add an event and say who is adding it';
  static const todos = 'To-dos';
  static const todosBody = 'Today’s jobs for everyone';
  static const meals = 'Meals';
  static const mealsBody = 'Today’s breakfast, lunch and supper';
  static const lunch = 'Lunch boxes';
  static const lunchBody = 'What’s in each child’s box today';
  static const people = 'Where everyone is';
  static const peopleBody =
      'Shows where everyone who shares their location is, on a map. Anyone '
      'in the room can see it, helpers and guests included.';
  static const peopleNeedsPremium = 'Part of Premium.';
  static const helperTitle = 'A helper’s day';
  static const helperBody = 'One helper’s jobs for today';
  static const chooseHelper = 'Whose day?';
  static const share = 'Open recipes and pages shared from phones';
  static const shareBody =
      'Share a recipe or any web page from your phone and the frame opens it';
  static const groceries = 'Add groceries from the frame';
  static const groceriesBody =
      'Anyone at the frame can add to the grocery list and pick a product '
      'from the shop below. The frame never fills a cart.';
  static const groceriesShop = 'Shop';
  static const groceriesArea = 'Prices near';
  static const linkAction = 'Link frame';
  static const linked = 'Linked — it’ll fill in a few seconds';
  static const done = 'Done';

  // ---- one frame ----
  static const editTitle = 'Frame settings';
  static const save = 'Save';
  static const unlink = 'Unlink frame';
  static const unlinkConfirm = 'Unlink this frame?';
  static String unlinkBody(String name) =>
      '$name goes back to showing a code. You can link it again any time.';
  static const keep = 'Keep it';

  // ---- a page shared from the phone ----
  static const showOnFrame = 'Show on frame';
  static String showOn(String name) => 'Show on $name';
  static const chooseFrame = 'Which frame should open it?';
  static String openingOn(String name) => 'Opening on $name';
  static const noSharingFrames = 'No frame opens recipes or pages yet';
  static const noSharingFramesBody =
      'Go to More → Photo frames, tap a frame and switch on “$share”.';
  static const shareOnlyFamily =
      'Only family can send to a frame. Ask a parent to send it.';
  static const noLinkShared =
      'There’s no web link in what you shared. Share the page itself and try '
      'again.';

  // ---- the screensaver ----
  static const screensaverTitle = 'Screensaver';
  static const screensaverBody =
      'When nobody has touched the frame for a while, it shows your photos. '
      'Until you choose a time and add photos, it shows a few NestPrep '
      'pictures after 10 minutes, so the screen never sits still.';
  static const screensaverOff = 'Off';
  static String idleMinutes(int minutes) => '$minutes min';
  static String idleMinutesLabel(int minutes) => minutes == 1
      ? 'Screensaver after 1 minute'
      : 'Screensaver after $minutes minutes';
  static const screensaverOffLabel =
      'Screensaver off, NestPrep pictures after 10 minutes';
  static const eachPhoto = 'Each photo';
  static String seconds(int seconds) => '$seconds s';
  static String secondsLabel(int seconds) => 'Each photo for $seconds seconds';
  static const screensaverNeedsPhotos =
      'The album is empty, so the frame shows a few NestPrep pictures for '
      'now. Add your own photos to show them instead.';

  // ---- the album ----
  static const photosTitle = 'Screensaver photos';
  static const photosIntro = 'Your frames show these when nobody’s using them.';
  static const photosEmptyTitle = 'No photos yet';
  static const photosEmptyBody =
      'Add a few favourites and every frame cycles through them when the '
      'house is quiet.';
  static const addPhotos = 'Add photos';
  static String adding(int current, int total) => 'Adding $current of $total';
  static String photoCount(int count) => '$count of ${FramePhoto.albumLimit}';
  static const albumFullHint = 'The album is full. Remove a few to add more.';
  static const albumEntryEmpty = 'None yet. Add a few for the screensaver';
  static const albumEntryBody = 'What frames show when nobody’s using them';
  static String photoLabel(int position) => 'Photo $position';
  static const photoLoading = 'Photo loading';
  static const photoFailed = 'Didn’t load';
  static const removePhotoConfirm = 'Remove this photo?';
  static const removePhotoBody =
      'It comes off every frame. The original stays on your phone.';
  static const removePhoto = 'Remove';
  static String addReport(FramePhotoAddReport report) {
    final skipped = switch (report.skipped) {
      0 => null,
      1 => 'One photo couldn’t be used.',
      final count => '$count photos couldn’t be used.',
    };
    final full = report.hitLimit
        ? 'The album holds ${FramePhoto.albumLimit}, so the rest were '
              'left out.'
        : null;
    return [?skipped, ?full].join(' ');
  }

  static String photoProblem(FramePhotoProblem problem) => switch (problem) {
    FramePhotoProblem.photoUnreadable =>
      'That photo couldn’t be read. Try a different one.',
    FramePhotoProblem.photoTooLarge =>
      'That photo is too big for the frames, even made smaller.',
    FramePhotoProblem.albumFull =>
      'The album holds ${FramePhoto.albumLimit} photos. Remove a few to '
          'make room.',
    FramePhotoProblem.libraryUnavailable =>
      'Your photo library wouldn’t open. Try again in a moment.',
  };

  static String problem(PhotoFrameProblem problem) => switch (problem) {
    PhotoFrameProblem.notFamily =>
      'Only a parent can link or change a frame. Ask one to do it.',
    PhotoFrameProblem.framesOff =>
      'Photo frames are resting for now. Try again a little later.',
    PhotoFrameProblem.frameCodeNotFound =>
      'That code didn’t match a frame. Check the letters and try again.',
    PhotoFrameProblem.frameCodeExpired =>
      'That code has run out. The frame shows a fresh one in a moment.',
    PhotoFrameProblem.tooManyFrames =>
      'Your household has all the frames it can. Unlink one first.',
    PhotoFrameProblem.helperNotFound =>
      'That helper isn’t in the household any more. Choose someone else.',
    PhotoFrameProblem.tooManyAttempts =>
      'That’s a lot of codes in a row. Wait a few minutes and try again.',
    PhotoFrameProblem.monthOutOfRange =>
      'A frame can only show a year either side of this month.',
    PhotoFrameProblem.itemNotFound =>
      'That task changed in the meantime. Here’s the latest.',
    PhotoFrameProblem.itemOutOfReach =>
      'A frame can tick off today and the last week only.',
    PhotoFrameProblem.whoNeeded => 'Choose who did it, then try again.',
    PhotoFrameProblem.addingOff =>
      'This frame doesn’t add events. Switch it on in the frame’s settings.',
    PhotoFrameProblem.notAllowedToAdd =>
      'That person can’t add to the calendar. Choose someone who can.',
    PhotoFrameProblem.eventOutOfReach =>
      'A frame can add events from today up to a year ahead.',
    PhotoFrameProblem.frameNotFound =>
      'That frame isn’t linked any more. Choose another one.',
    PhotoFrameProblem.sharingOff =>
      'That frame doesn’t open recipes or pages. Switch it on in the frame’s '
          'settings.',
    PhotoFrameProblem.badLink =>
      'That page can’t open on a frame. Share a link to a public website.',
    PhotoFrameProblem.frameCantOpen =>
      'That frame needs an update first. Update nestprep Home on it, then '
          'try again.',
    PhotoFrameProblem.recipeNotFound =>
      'That recipe isn’t available any more. Choose another one.',
    PhotoFrameProblem.badRecipe =>
      'That recipe couldn’t be sent as it is. Open it again and try once '
          'more.',
    PhotoFrameProblem.groceriesOff =>
      'This frame doesn’t add groceries. Switch it on in the frame’s '
          'settings.',
    PhotoFrameProblem.notAllowedToAddGroceries =>
      'That person can’t add to the grocery list. Choose someone who can.',
    PhotoFrameProblem.shopUnavailable =>
      'The shop isn’t answering just now. Try again in a moment.',
  };
}
