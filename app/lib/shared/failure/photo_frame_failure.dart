part of 'app_failure.dart';

enum PhotoFrameProblem {
  notFamily,
  framesOff,
  frameCodeNotFound,
  frameCodeExpired,
  tooManyFrames,
  helperNotFound,
  tooManyAttempts,
  monthOutOfRange,
  itemNotFound,
  itemOutOfReach,
  whoNeeded,
  addingOff,
  notAllowedToAdd,
  eventOutOfReach,
  frameNotFound,
  sharingOff,
  badLink,
  frameCantOpen,
  recipeNotFound,
  badRecipe,
  groceriesOff,
  notAllowedToAddGroceries,
  shopUnavailable,
}

final class PhotoFrameFailure extends AppFailure {
  const PhotoFrameFailure(this.problem);

  final PhotoFrameProblem problem;
}

enum FramePhotoProblem {
  photoUnreadable,
  photoTooLarge,
  albumFull,
  libraryUnavailable,
}

final class FramePhotoFailure extends AppFailure {
  const FramePhotoFailure(this.problem);

  final FramePhotoProblem problem;
}
