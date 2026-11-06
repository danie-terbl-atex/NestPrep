import 'package:flutter/foundation.dart';

/// Whether the signed-in member's own account at one shop is linked, the
/// same way for every shop: yes or no, and the masked number or email the
/// shop's status names when it names one.
@immutable
final class ShopLink {
  const ShopLink({required this.isLinked, this.account});

  const ShopLink.unlinked() : isLinked = false, account = null;

  final bool isLinked;
  final String? account;

  @override
  bool operator ==(Object other) =>
      other is ShopLink &&
      other.isLinked == isLinked &&
      other.account == account;

  @override
  int get hashCode => Object.hash(isLinked, account);
}
