import 'grant_source.dart';

sealed class PremiumLength {
  const PremiumLength(this.count);

  factory PremiumLength.of(GrantSource source, int days) => switch (source) {
    GrantSource.referral => PremiumMonths((days + 29) ~/ 30),
    GrantSource.frame when days % 31 == 0 => PremiumMonths(days ~/ 31),
    GrantSource.frame || GrantSource.code => PremiumDays(days),
  };

  final int count;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is PremiumLength &&
      other.count == count;

  @override
  int get hashCode => Object.hash(runtimeType, count);
}

final class PremiumMonths extends PremiumLength {
  const PremiumMonths(super.count);
}

final class PremiumDays extends PremiumLength {
  const PremiumDays(super.count);
}
