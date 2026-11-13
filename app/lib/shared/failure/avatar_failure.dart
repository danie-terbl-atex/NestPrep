part of 'app_failure.dart';

enum AvatarProblem { pickerUnavailable, photoUnreadable, photoTooLarge }

final class AvatarFailure extends AppFailure {
  const AvatarFailure(this.problem);

  final AvatarProblem problem;
}
