/// Photo updates' words (`FE-19`, nanny-hub ADR-0004): what a carer taps to
/// send the parents a picture mid-shift, and the parents' live feed of them.
abstract final class NannyPhotoCopy {
  // Shift mode.
  static const sendTitle = 'Send the parents a photo';
  static const sendBody =
      'A quick picture of how it is going. It reaches them straight away.';
  static const takeOne = 'Open the camera';
  static const chooseOne = 'Choose from your photos';
  static const sheetTitle = 'Send this photo?';
  static const caption = 'A few words (optional)';
  static const captionHint = 'Building a fort in the lounge';
  static const send = 'Send to the parents';
  static const sending = 'Sending…';
  static const photoLabel = 'The photo you are sending';
  static String sentSoFar(int count) =>
      count == 1 ? '1 photo sent this shift' : '$count photos sent this shift';

  // The feed.
  static const feedTitle = 'Photos from the shift';
  static const live = 'Live';
  static const ended = 'Shift ended';
  static String feedHeader(String carer, String since) =>
      '$carer’s shift, since $since';
  static const liveEmptyTitle = 'No photos yet';
  static String liveEmptyBody(String carer) =>
      'They appear here the moment $carer sends one.';
  static const endedEmptyTitle = 'No photos from this shift';
  static const endedEmptyBody =
      'Nothing was sent. The handover summary has the rest.';
  static const goneTitle = 'This shift is not here';
  static const goneBody = 'It may have been removed. Go back to the hub.';
  static String from(String carer, String time) => 'From $carer at $time';
  static const somebody = 'the carer';
  static const pending = 'Sending…';
  static const remove = 'Take back this photo';
  static const removeConfirm = 'Take this photo back?';
  static const removeBody = 'The parents will no longer see it.';
  static const removeAction = 'Take it back';
  static String photoOf(String? caption) => caption ?? 'A photo from the shift';

  // The hub's home and a summary.
  static String liveFrom(String carer) => 'Live from $carer’s shift';
  static const liveFromBody = 'Photos arrive here as they are sent.';
  static const shiftPhotos = 'Photos from this shift';
}
