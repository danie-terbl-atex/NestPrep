import '../../../shared/failure/app_failure.dart';
import 'cart_push_result.dart';

/// Where one *Add to Checkers* stands, for the result sheet.
sealed class CartPushState {
  const CartPushState();
}

final class CartPushIdle extends CartPushState {
  const CartPushIdle();
}

final class CartPushing extends CartPushState {
  const CartPushing();
}

/// The member's Checkers link has run out, or never was: link, then retry.
final class CartPushNeedsLink extends CartPushState {
  const CartPushNeedsLink();
}

final class CartPushed extends CartPushState {
  const CartPushed(this.result);

  final CartPushResult result;
}

final class CartPushFailed extends CartPushState {
  const CartPushFailed(this.failure);

  final AppFailure failure;
}
