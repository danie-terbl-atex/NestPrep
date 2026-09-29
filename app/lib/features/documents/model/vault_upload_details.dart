import '../../../shared/time/calendar_date.dart';

/// What a person said about a document before it was added to a vault: whose
/// it is, what it is called, how it is tagged, and when it expires.
class VaultUploadDetails {
  const VaultUploadDetails({
    required this.ownerMemberId,
    required this.name,
    this.tags = const [],
    this.expiresOn,
  });

  final String ownerMemberId;
  final String name;
  final List<String> tags;
  final CalendarDate? expiresOn;
}
