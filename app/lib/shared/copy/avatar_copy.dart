import '../../features/avatars/model/avatar_catalogue.g.dart';
import '../../features/avatars/model/avatar_purchase.dart';
import '../../features/avatars/model/avatar_stage.dart';
import '../failure/app_failure.dart';
import 'points_copy.dart';

abstract final class AvatarCopy {
  // ---- ways in ----
  static const changePicture = 'Change picture';
  static String changePictureOf(String name) => 'Change $name’s picture';

  // ---- the studio ----
  static const yourTitle = 'Your picture';
  static String title(String name) => '$name’s picture';
  static const nestlings = 'Nestlings';
  static const photo = 'Photo';
  static const wardrobe = 'Wardrobe';
  static const useMyInitial = 'Use my initial';
  static String useInitialOf(String name) => 'Use $name’s initial';

  // ---- Nestlings ----
  static const pickNestling = 'Pick a Nestling';
  static const pickNestlingBody =
      'Each Nestling grows up in four stages. Pick one, then how grown-up.';
  static const howGrownUp = 'How grown-up';
  static String stageName(int stage) => switch (stage) {
    AvatarStage.egg => 'Egg',
    AvatarStage.hatchling => 'Hatchling',
    AvatarStage.fledgling => 'Fledgling',
    _ => 'Flyer',
  };
  static String nestlingAt(String name, int stage) =>
      '$name, ${stageName(stage).toLowerCase()}';

  // ---- a kid's Nestling grows with their stars ----
  static const kidPickTitle = 'Pick your Nestling';
  static const kidEggTitle = 'Earn your first star to hatch!';
  static const kidEggBody =
      'Your Nestling is waiting in its egg. Finish a job with stars and it '
      'hatches.';
  static const kidHatchlingTitle = 'Grow some wings!';
  static String kidHatchlingBody(int toGo) => toGo == 1
      ? 'Do your jobs 1 more day in a row and your Nestling grows up.'
      : 'Do your jobs $toGo more days in a row and your Nestling grows up.';
  static const kidFledglingTitle = 'Nearly ready to fly!';
  static String kidFledglingBody(int toGo) => toGo == 1
      ? 'Do your jobs 1 more day in a row and your Nestling can fly.'
      : 'Do your jobs $toGo more days in a row and your Nestling can fly.';
  static const kidFlyerTitle = 'All grown up!';
  static const kidFlyerBody = 'Your Nestling can fly. Look how far it came.';
  static String daysInARow(int done, int needed) => '$done of $needed days';
  static String parentStageBody(String name) =>
      '$name’s Nestling hatches with their first star and grows when they do '
      'their jobs three, then seven days in a row.';

  // ---- photo ----
  static const takePhoto = 'Take a photo';
  static const choosePhoto = 'Choose a photo';
  static const photoBody =
      'A face, a pet or a favourite toy. It stays in your household, and '
      'where it was taken is removed.';
  static const cropTitle = 'Fit it in the circle';
  static const cropHint = 'Pinch and drag until it looks right.';
  static const usePhoto = 'Use this photo';
  static const tryAnother = 'Try another';
  static const savingPhoto = 'Saving your photo…';

  // ---- wardrobe ----
  static const wardrobeBody =
      'Tap something to wear it. Tap again to take it off.';
  static String slotTitle(AvatarSlot slot) => switch (slot) {
    AvatarSlot.top => 'On top',
    AvatarSlot.face => 'Glasses and masks',
    AvatarSlot.badge => 'Badges',
    AvatarSlot.ring => 'Frames',
  };
  static const yours = 'Yours';
  static String wear(String label) => 'Wear the ${label.toLowerCase()}';
  static String takeOff(String label) => 'Take off the ${label.toLowerCase()}';
  static const faceNeedsNestling = 'Glasses and masks are for Nestlings.';

  // ---- the star shop ----
  static const shopTitle = 'Star shop';
  static String shopBody(int stars) =>
      'You have ${PointsCopy.starsCount(stars)}. Spend them on something new.';
  static String shopBodyOf(String name, int stars) =>
      '$name has ${PointsCopy.starsCount(stars)} to spend on something new.';
  static String buyFor(int stars) => 'Buy for ${PointsCopy.starsCount(stars)}';
  static String moreStars(int more) =>
      '${PointsCopy.starsCount(more)} more to go';
  static String buyConfirm(String label, int stars) =>
      'Buy the ${label.toLowerCase()} for ${PointsCopy.starsCount(stars)}?';
  static const buyConfirmBody = 'The stars come off straight away.';
  static const buyYes = 'Buy it';
  static const buyNotYet = 'Not yet';
  static String boughtTitle(String label) =>
      'The ${label.toLowerCase()} is yours!';
  static const boughtBody = 'You’re wearing it now.';
  static String boughtTitleOf(String name, String label) =>
      'The ${label.toLowerCase()} is $name’s!';
  static String boughtBodyOf(String name) => '$name is wearing it now.';
  static const tooSlow =
      'That’s taking longer than usual. Try again in a moment.';
  static String refused(PurchaseRefusal? reason) => switch (reason) {
    PurchaseRefusal.notEnoughStars =>
      'Not quite enough stars for that one yet.',
    PurchaseRefusal.alreadyOwned => 'You have that one already.',
    PurchaseRefusal.shopOff => 'The star shop is closed for now.',
    PurchaseRefusal.notAKid => 'The star shop is for children’s stars.',
    PurchaseRefusal.unknownAccessory ||
    null => 'That one is not in the shop any more.',
  };
  static const shopClosed =
      'The star shop is closed. A grown-up can open it again under Stars.';

  static const premiumAskParent =
      'This is part of Premium. Ask a parent about it.';

  // ---- the kid home ----
  static const kidShelfTitle = 'Your Nestling';
  static const kidShelfBody = 'Hats, badges and frames to spend your stars on.';
  static const kidShelfAction = 'Open the wardrobe';
  static const kidShelfClosedBody = 'Hats, badges and frames to dress it up.';

  // ---- the parent's switch, on Stars and rewards ----
  static const shopSwitchTitle = 'Star shop for pictures';
  static const shopSwitchBody =
      'Children can spend stars on hats and badges for their Nestling, '
      'straight away. Turn it off to keep stars for your rewards.';

  // ---- hatching and growing ----
  static const hatchedTitle = 'Your egg hatched!';
  static String hatchedBody(String nestling) => 'Say hello to $nestling.';
  static const grewTitle = 'Look, wings!';
  static const grewBody = 'Your Nestling is growing up.';
  static const flewTitle = 'Ready to fly!';
  static const flewBody = 'Your Nestling is all grown up.';

  static String problem(AvatarProblem problem) => switch (problem) {
    AvatarProblem.pickerUnavailable =>
      'The camera or your photos would not open.',
    AvatarProblem.photoUnreadable => 'That photo could not be read.',
    AvatarProblem.photoTooLarge => 'That photo is too big. Try another one.',
  };
}
