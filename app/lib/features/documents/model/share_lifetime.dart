/// How long a shared link lasts (documents ADR-0006): one of the fixed
/// lengths, or until a nanny-hub shift that is on now ends.
sealed class ShareLifetime {
  const ShareLifetime();

  /// The lengths a person may choose, in hours. The same list is
  /// `SHARE_LIFETIME_HOURS` in `functions/src/documents/share/share_policy.ts`,
  /// and `share_lifetime_contract_test.dart` reads both.
  static const hourOptions = [1, 4, 24, 72, 168];

  /// A day: long enough for most errands, short enough to forget safely.
  static const suggested = HoursLifetime(24);
}

final class HoursLifetime extends ShareLifetime {
  const HoursLifetime(this.hours);

  final int hours;

  @override
  bool operator ==(Object other) =>
      other is HoursLifetime && other.hours == hours;

  @override
  int get hashCode => hours.hashCode;
}

final class ShiftLifetime extends ShareLifetime {
  const ShiftLifetime({required this.shiftId, required this.carerName});

  final String shiftId;

  /// Whose shift, for the choice a parent reads.
  final String carerName;

  @override
  bool operator ==(Object other) =>
      other is ShiftLifetime && other.shiftId == shiftId;

  @override
  int get hashCode => shiftId.hashCode;
}
