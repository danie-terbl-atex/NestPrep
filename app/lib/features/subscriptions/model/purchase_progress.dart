import '../../../shared/failure/app_failure.dart';

/// Where a purchase or a restore the person started has got to
/// (subscriptions ADR-0001). One at a time: the paywall and the plan screen
/// both show it, and a second tap while one is running does nothing.
sealed class PurchaseProgress {
  const PurchaseProgress();

  bool get isBusy => false;
}

final class PurchaseIdle extends PurchaseProgress {
  const PurchaseIdle();
}

/// The store's own sheet is open.
final class PurchaseInStore extends PurchaseProgress {
  const PurchaseInStore();

  @override
  bool get isBusy => true;
}

/// The store has taken the payment, or found an old one, and the server is
/// checking it with the store before premium is written.
final class PurchaseVerifying extends PurchaseProgress {
  const PurchaseVerifying({required this.isRestore});

  final bool isRestore;

  @override
  bool get isBusy => true;
}

/// Waiting on somebody else — a parent's approval, a payment that settles
/// later. Premium arrives when it goes through, even if the app is closed.
final class PurchaseAwaitingApproval extends PurchaseProgress {
  const PurchaseAwaitingApproval();
}

/// The household has premium.
final class PurchaseSucceeded extends PurchaseProgress {
  const PurchaseSucceeded();
}

/// Said in words by `AppCopy.failure`; never the store's own message.
final class PurchaseFailed extends PurchaseProgress {
  const PurchaseFailed(this.failure);

  final AppFailure failure;
}
