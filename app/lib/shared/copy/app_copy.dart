import '../failure/app_failure.dart';

/// Every user-facing string in the app (`FE-19`). Screens read from here and
/// nowhere else, so tone stays in one place and translation is later work.
abstract final class AppCopy {
  static const appName = 'NestPrep';

  static const diagnosticsTitle = 'NestPrep';
  static const diagnosticsSubtitle = 'Emulator check';
  static const diagnosticsEmptyTitle = 'No pings yet';
  static const diagnosticsEmptyBody =
      'Send one to check the app can reach Firestore.';
  static const diagnosticsSendPing = 'Send a ping';
  static const diagnosticsPingPending = 'Sending…';
  static const diagnosticsPingFrom = 'From';
  static const loading = 'Loading';
  static const retry = 'Try again';
  static const back = 'Back';

  static const galleryTitle = 'Design kit';
  static const galleryToggleTheme = 'Switch light and dark';
  static const galleryControls = 'Controls';
  static const gallerySurfaces = 'Surfaces';
  static const galleryStates = 'States';

  static String failure(AppFailure failure) => switch (failure) {
    PermissionDeniedFailure() => 'You are not allowed to do that.',
    UnavailableFailure() =>
      'NestPrep cannot reach the server right now. Check your connection.',
    NotFoundFailure() => 'That is no longer there.',
    UnknownFailure() => 'Something went wrong. Please try again.',
  };
}
