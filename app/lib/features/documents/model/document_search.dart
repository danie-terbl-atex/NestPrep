import 'package:flutter/foundation.dart';

import '../../../shared/time/calendar_date.dart';
import 'document_entry.dart';
import 'expiry_schedule.dart';

/// Whose documents a search is limited to.
sealed class OwnerFilter {
  const OwnerFilter();

  static const anyone = AnyOwner();
  static const household = HouseholdOwner();
}

final class AnyOwner extends OwnerFilter {
  const AnyOwner();
}

/// The household's shared folders, not anybody's vault.
final class HouseholdOwner extends OwnerFilter {
  const HouseholdOwner();
}

final class MemberOwner extends OwnerFilter {
  const MemberOwner(this.memberId);

  final String memberId;

  @override
  bool operator ==(Object other) =>
      other is MemberOwner && other.memberId == memberId;

  @override
  int get hashCode => memberId.hashCode;
}

/// What somebody is looking for: words, a person, a tag, and whether only the
/// documents that need attention soon.
@immutable
class DocumentQuery {
  const DocumentQuery({
    this.text = '',
    this.owner = OwnerFilter.anyone,
    this.tag,
    this.expiringSoonOnly = false,
  });

  final String text;
  final OwnerFilter owner;
  final String? tag;
  final bool expiringSoonOnly;

  bool get isEmpty =>
      text.trim().isEmpty &&
      owner is AnyOwner &&
      tag == null &&
      !expiringSoonOnly;

  DocumentQuery copyWith({
    String? text,
    OwnerFilter? owner,
    String? Function()? tag,
    bool? expiringSoonOnly,
  }) => DocumentQuery(
    text: text ?? this.text,
    owner: owner ?? this.owner,
    tag: tag == null ? this.tag : tag(),
    expiringSoonOnly: expiringSoonOnly ?? this.expiringSoonOnly,
  );
}

/// Search over documents already in memory (documents ADR-0005).
///
/// Every list it reads is a bounded listener, so there is no query per
/// keystroke and nothing to index; a household of 200 documents is filtered in
/// well under a frame. Each word typed must appear somewhere — in the name, a
/// tag, the folder, or the name of the person whose vault it is — so "emma
/// passport" finds Emma's passport and not every passport.
List<DocumentEntry> searchDocuments(
  Iterable<DocumentEntry> entries,
  DocumentQuery query, {
  required CalendarDate today,
  Map<String, String> ownerNames = const {},
}) {
  final words = query.text
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  final tag = query.tag?.toLowerCase();

  bool matches(DocumentEntry entry) {
    if (!_isOwnedAs(entry, query.owner)) return false;
    if (tag != null && !entry.tags.any((t) => t.toLowerCase() == tag)) {
      return false;
    }
    if (query.expiringSoonOnly &&
        !ExpirySchedule.statusOf(entry.expiresOn, today).needsAttention) {
      return false;
    }
    if (words.isEmpty) return true;
    final haystack = _haystackOf(entry, ownerNames);
    return words.every(haystack.contains);
  }

  final found = entries.where(matches).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return found;
}

bool _isOwnedAs(DocumentEntry entry, OwnerFilter owner) => switch (owner) {
  AnyOwner() => true,
  HouseholdOwner() => entry.ownerMemberId == null,
  MemberOwner(:final memberId) => entry.ownerMemberId == memberId,
};

String _haystackOf(DocumentEntry entry, Map<String, String> ownerNames) {
  final folder = switch (entry) {
    HouseholdEntry(:final folderName) => folderName ?? '',
    VaultEntry() => '',
  };
  final owner = ownerNames[entry.ownerMemberId] ?? '';
  return [entry.name, ...entry.tags, folder, owner].join(' ').toLowerCase();
}

/// The documents that need attention soon — expired, due today, or inside the
/// second reminder — most urgent first.
List<DocumentEntry> expiringSoon(
  Iterable<DocumentEntry> entries, {
  required CalendarDate today,
}) {
  final soon = entries
      .where(
        (entry) =>
            ExpirySchedule.statusOf(entry.expiresOn, today).needsAttention,
      )
      .toList();
  soon.sort((a, b) => (a.expiresOn ?? today).compareTo(b.expiresOn ?? today));
  return soon;
}
