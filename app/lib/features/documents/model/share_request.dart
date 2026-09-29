import 'share_lifetime.dart';

/// Everything `createDocumentShare` is asked (documents ADR-0006). Whether the
/// asker may share it, the document's name and when it really ends are the
/// server's to work out; this is only what the person chose.
class ShareRequest {
  const ShareRequest({
    required this.householdId,
    required this.ownerMemberId,
    required this.documentId,
    required this.lifetime,
    required this.pin,
  });

  final String householdId;

  /// The vault it is in, or null for a household document.
  final String? ownerMemberId;
  final String documentId;
  final ShareLifetime lifetime;

  /// Four to eight digits, or null for a link with no PIN.
  final String? pin;

  static const pinMinLength = 4;
  static const pinMaxLength = 8;

  /// Whether [pin] is one the server will take: digits only, 4 to 8 of them.
  static bool isPin(String pin) => RegExp(r'^[0-9]{4,8}$').hasMatch(pin);
}
