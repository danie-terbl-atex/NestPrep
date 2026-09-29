/// What the store last said about the subscription behind the household's
/// premium (subscriptions ADR-0001). The names are the server's
/// `PURCHASE_STATUSES`, plus `none` for a household that has never bought.
///
/// It says *why*, for the plan screen. Whether the household has premium is
/// `Entitlement.premiumUntil` alone, which is what the rules compare.
enum EntitlementStatus {
  none,
  active,

  /// It will not renew, and runs until the date already paid for.
  cancelled,

  /// The store is retrying a payment and the family keeps premium meanwhile.
  inGracePeriod,

  /// The store gave up retrying for now; premium is paused until it is paid.
  onHold,
  paused,
  pending,
  expired,

  /// Refunded or taken back by the store.
  revoked,
}
