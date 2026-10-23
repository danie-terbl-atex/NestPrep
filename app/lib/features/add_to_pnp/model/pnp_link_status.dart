import 'package:flutter/foundation.dart';

/// Whether the signed-in member's own Pick n Pay account is linked, as
/// `pnpLinkStatus` answers it. The tokens stay on the server; the phone only
/// hears yes or no, and since when (add-to-pnp ADR-0003).
@immutable
final class PnpLinkStatus {
  const PnpLinkStatus({required this.isLinked, this.linkedAt});

  const PnpLinkStatus.unlinked() : isLinked = false, linkedAt = null;

  final bool isLinked;
  final DateTime? linkedAt;
}
