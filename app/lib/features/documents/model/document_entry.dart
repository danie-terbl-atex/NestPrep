import '../../../shared/time/calendar_date.dart';
import 'household_document.dart';
import 'vault_document.dart';

/// Any document a person can find — the household's, or one in a vault —
/// seen through the fields search and "expiring soon" care about.
///
/// A sealed pair rather than one merged model, because the two live in
/// different places under different rules (documents ADR-0002), and opening one
/// is a different act: a household document is read directly, a vault document
/// through the logged callable.
sealed class DocumentEntry {
  const DocumentEntry();

  String get id;
  String get name;
  List<String> get tags;
  CalendarDate? get expiresOn;
  String get contentType;
  int get sizeBytes;

  /// The vault's member, or null for the household's shared papers.
  String? get ownerMemberId;
}

final class HouseholdEntry extends DocumentEntry {
  const HouseholdEntry(this.document, {required this.folderName});

  final HouseholdDocument document;

  /// The folder it is filed in, for the result row.
  final String? folderName;

  @override
  String get id => document.id;
  @override
  String get name => document.name;
  @override
  List<String> get tags => document.tags;
  @override
  CalendarDate? get expiresOn => document.expiresOn;
  @override
  String get contentType => document.contentType;
  @override
  int get sizeBytes => document.sizeBytes;
  @override
  String? get ownerMemberId => null;
}

final class VaultEntry extends DocumentEntry {
  const VaultEntry(this.document);

  final VaultDocument document;

  @override
  String get id => document.id;
  @override
  String get name => document.name;
  @override
  List<String> get tags => document.tags;
  @override
  CalendarDate? get expiresOn => document.expiresOn;
  @override
  String get contentType => document.contentType;
  @override
  int get sizeBytes => document.sizeBytes;
  @override
  String? get ownerMemberId => document.ownerMemberId;
}
