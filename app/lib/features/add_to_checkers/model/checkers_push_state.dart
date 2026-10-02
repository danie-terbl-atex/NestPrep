import '../../../shared/failure/app_failure.dart';
import 'checkers_push_result.dart';

/// Where one *Add to Checkers* stands, for the result sheet.
sealed class CheckersPushState {
  const CheckersPushState();
}

final class CheckersPushIdle extends CheckersPushState {
  const CheckersPushIdle();
}

final class CheckersPushing extends CheckersPushState {
  const CheckersPushing();
}

/// The member's Checkers link has run out, or never was: link, then retry.
final class CheckersPushNeedsLink extends CheckersPushState {
  const CheckersPushNeedsLink();
}

final class CheckersPushed extends CheckersPushState {
  const CheckersPushed(this.result);

  final CheckersPushResult result;
}

final class CheckersPushFailed extends CheckersPushState {
  const CheckersPushFailed(this.failure);

  final AppFailure failure;
}
