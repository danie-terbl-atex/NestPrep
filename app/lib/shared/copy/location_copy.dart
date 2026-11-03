import '../../features/live_location/model/family_place.dart';
import '../../features/live_location/model/member_location.dart';

/// Every word the family map says (`FE-19`, live-location ADR-0003 to
/// ADR-0007), exported from `app_copy.dart`.
abstract final class LocationCopy {
  static const title = 'Where we are';
  static const yours = 'Your location';
  static const yoursBody =
      'Only you can start or stop this, and every share ends on its own.';
  static const shareFor = 'Share for';
  static const stop = 'Stop sharing';
  static const sharingUntil = 'Sharing until';
  static const fifteenMinutes = '15 minutes';
  static const oneHour = '1 hour';
  static const fourHours = '4 hours';
  static const hereNow = 'Here now';
  static const lastSeen = 'Last seen';
  static const notSharing = 'Not sharing';
  static const aloneTitle = 'Nobody else here yet';
  static const aloneBody =
      'Add the people who live here, and this is where you will see who is out.';

  static const always = 'Always share';
  static const alwaysBody =
      'Keep sharing when NestPrep is closed, so your family sees you arrive.';
  static const alwaysOn = 'Sharing all the time';
  static const alwaysOnBody =
      'Your family can see where you are. Pause any time — only you can '
      'turn this on or off.';
  static const pause = 'Pause sharing';
  static const batteryHint = 'Sharing keeps stopping?';

  static const disclosureTitle = 'Share where you are, all the time';
  static const disclosurePoints = [
    'NestPrep collects this phone’s location in the background — even when '
        'the app is closed or not in use — so your family can see where you '
        'are on the map.',
    'It keeps 30 days of where you have been, and tells your family when you '
        'reach or leave places like home or school.',
    'Only people your household lets see the map can see it. Nobody else, '
        'and never for advertising.',
    'It uses the phone’s motion sensors to switch location off while you '
        'are still, which saves battery. Your phone may ask about that next.',
    'You can pause it any time: here, or from the notification on Android.',
  ];
  static const disclosureNext =
      'Next, your phone will ask. Choose “Allow all the time”.';
  static const disclosureContinue = 'Continue';
  static const disclosureNotNow = 'Not now';

  static const notificationTitle = 'Sharing your location';
  static String notificationBody(String household) =>
      '$household can see where you are.';
  static const notificationChannel = 'Location sharing';
  static const notificationPause = 'Pause';

  static const stoppedRefused =
      'Always sharing stopped. Premium may have ended, or you can no longer '
      'share in this household.';
  static const stoppedPermission =
      'Always sharing stopped because location was turned off for NestPrep.';
  static const stoppedSignedOut =
      'Always sharing stopped because you signed out.';

  static String battery(int percent, {required bool charging}) =>
      charging ? '$percent% · charging' : '$percent%';

  static String motion(DeviceMotion motion) => switch (motion) {
    DeviceMotion.still => 'Still',
    DeviceMotion.onFoot => 'On foot',
    DeviceMotion.cycling => 'Cycling',
    DeviceMotion.driving => 'Driving',
    DeviceMotion.unknown => 'Moving',
  };

  static String atPlace(String place) => 'At $place';
  static String mapLabel(int people) => people == 1
      ? 'Map of where we are, 1 person on it'
      : 'Map of where we are, $people people on it';
  static const near = 'Near';

  static const map = 'Map';
  static const everybody = 'Everybody';
  static const history = 'Where they’ve been';
  static String historyOf(String name) => 'Where $name has been';
  static const today = 'Today';
  static const yesterday = 'Yesterday';
  static const previousDay = 'Previous day';
  static const nextDay = 'Next day';
  static const emptyDayTitle = 'Nothing recorded';
  static const emptyDayBody =
      'Nothing was shared this day. History is kept for 30 days, only while '
      'always sharing is on.';
  static String stayed(String duration) => 'Stayed $duration';

  static String duration(Duration length) {
    final hours = length.inHours;
    final minutes = length.inMinutes % 60;
    if (hours == 0) return '$minutes min';
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }

  static String distance(double metres) => metres < 1000
      ? '${metres.round()} m'
      : '${(metres / 1000).toStringAsFixed(1)} km';
  static String arrived(String place) => 'Arrived at $place';
  static String left(String place) => 'Left $place';
  static const somewhere = 'Somewhere';
  static const clearHistory = 'Clear my history';
  static const clearHistoryConfirm =
      'Delete everything recorded about where you have been? This cannot be '
      'undone.';
  static const clear = 'Clear';
  static const cancel = 'Cancel';

  static const places = 'Places';
  static const placesBody =
      'Home, school, gran’s. Get a notification when somebody arrives or '
      'leaves.';
  static const noPlacesTitle = 'No places yet';
  static const noPlacesBody =
      'Add home and school to hear when everybody gets there.';
  static const addPlace = 'Add a place';
  static const editPlace = 'Edit place';
  static const placeName = 'Name';
  static const placeNameHint = 'Home, school, gran’s…';
  static String radius(int metres) => '$metres m around it';
  static const useWhereIAm = 'Use where I am now';
  static const dragToPlace = 'Drag the map to put the pin on the place.';
  static const noCentreYet = 'Choose where it is first.';
  static const alertArrive = 'Tell us when somebody arrives';
  static const alertLeave = 'Tell us when somebody leaves';
  static const save = 'Save';
  static const deletePlace = 'Delete place';
  static const placesFull = 'A household holds up to 30 places.';
  static const placeGoneTitle = 'That place has gone';
  static const placeGoneBody = 'Somebody in your household removed it.';

  static String icon(PlaceIcon icon) => switch (icon) {
    PlaceIcon.home => 'Home',
    PlaceIcon.school => 'School',
    PlaceIcon.work => 'Work',
    PlaceIcon.sport => 'Sport',
    PlaceIcon.shop => 'Shop',
    PlaceIcon.family => 'Family',
    PlaceIcon.other => 'Other',
  };
}
