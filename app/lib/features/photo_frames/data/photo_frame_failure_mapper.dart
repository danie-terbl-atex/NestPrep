import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../shared/failure/app_failure.dart';
import '../../../shared/failure/storage_failure_mapper.dart';
import '../../../shared/log/app_log.dart';
import '../../household/data/household_failure_mapper.dart';

AppFailure failureFromFrameCallable(FirebaseFunctionsException error) {
  final details = error.details;
  final reason = details is Map ? details['reason'] : null;
  final problem = PhotoFrameProblem.values
      .where((value) => value.name == reason)
      .firstOrNull;
  if (problem == null) return failureFromCallable(error);
  AppLog.failure('photo frame callable', code: error.code, error: error);
  return PhotoFrameFailure(problem);
}

AppFailure failureFromFramePhotoStorage(Object error) {
  if (error is FirebaseException && error.code == 'storage/unauthorized') {
    AppLog.failure('frame photos', code: error.code, error: error);
    return const PhotoFrameFailure(PhotoFrameProblem.notFamily);
  }
  return failureFromStorage(error);
}
