import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_entry.dart';
import 'package:nestprep/features/documents/model/document_search.dart';
import 'package:nestprep/features/documents/model/household_document.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

import '../../../support/fake_vault.dart';

/// Search by name, person and tag, over what the listeners already hold
/// (documents ADR-0005). The phase's line: a household of 200 documents is
/// searched without an unbounded query — so it is searched here, at 200.
void main() {
  final today = CalendarDate(2027, 6, 1);
  const names = {'m-emma': 'Emma Parker', 'm-sam': 'Sam Parker'};

  HouseholdEntry household(
    String id,
    String name, {
    List<String> tags = const [],
    CalendarDate? expiresOn,
    String folder = 'Insurance',
  }) => HouseholdEntry(
    HouseholdDocument(
      id: id,
      folderId: 'f',
      name: name,
      contentType: 'application/pdf',
      sizeBytes: 1,
      uploadedBy: 'm-sam',
      tags: tags,
      expiresOn: expiresOn,
    ),
    folderName: folder,
  );

  VaultEntry vault(
    String id,
    String owner,
    String name, {
    List<String> tags = const [],
    CalendarDate? expiresOn,
  }) => VaultEntry(
    vaultDocument(
      id,
      name: name,
      tags: tags,
      expiresOn: expiresOn,
    ).copyWith(ownerMemberId: owner),
  );

  final entries = <DocumentEntry>[
    household(
      'car',
      'Car insurance',
      tags: ['Car'],
      expiresOn: today.addDays(20),
    ),
    household('lease', 'Lease', folder: 'Home'),
    vault('emma-pp', 'm-emma', 'Passport', tags: ['ID', 'Travel']),
    vault('sam-pp', 'm-sam', 'Passport', expiresOn: today.addDays(-3)),
    vault('emma-rep', 'm-emma', 'School report', tags: ['School']),
  ];

  List<String> ids(DocumentQuery query) => [
    for (final entry in searchDocuments(
      entries,
      query,
      today: today,
      ownerNames: names,
    ))
      entry.id,
  ];

  test('an empty query finds everything, by name', () {
    expect(ids(const DocumentQuery()), [
      'car',
      'lease',
      'emma-pp',
      'sam-pp',
      'emma-rep',
    ]);
  });

  test('every word must match somewhere — name, tag, folder or person', () {
    expect(ids(const DocumentQuery(text: 'passport')), ['emma-pp', 'sam-pp']);
    expect(ids(const DocumentQuery(text: 'emma passport')), ['emma-pp']);
    expect(ids(const DocumentQuery(text: 'TRAVEL')), ['emma-pp']);
    expect(ids(const DocumentQuery(text: 'home')), ['lease']);
    expect(ids(const DocumentQuery(text: 'nothing like it')), isEmpty);
  });

  test('by person, and "household" means the shared folders only', () {
    expect(ids(const DocumentQuery(owner: MemberOwner('m-emma'))), [
      'emma-pp',
      'emma-rep',
    ]);
    expect(ids(const DocumentQuery(owner: OwnerFilter.household)), [
      'car',
      'lease',
    ]);
  });

  test('by tag, whatever its case', () {
    expect(ids(const DocumentQuery(tag: 'school')), ['emma-rep']);
  });

  test('"expiring soon" is what needs attention now, household and vault', () {
    expect(ids(const DocumentQuery(expiringSoonOnly: true)), ['car', 'sam-pp']);
  });

  test('the filters combine', () {
    expect(
      ids(
        const DocumentQuery(
          text: 'passport',
          owner: MemberOwner('m-sam'),
          expiringSoonOnly: true,
        ),
      ),
      ['sam-pp'],
    );
  });

  test('expiring soon lists the most urgent first', () {
    expect(
      [for (final entry in expiringSoon(entries, today: today)) entry.id],
      ['sam-pp', 'car'],
    );
  });

  test('a household of 200 documents is searched in memory, well inside a '
      'frame', () {
    final many = <DocumentEntry>[
      for (var i = 0; i < 150; i++)
        household('h$i', 'Household paper $i', tags: ['Tag${i % 12}']),
      for (var i = 0; i < 50; i++)
        vault('v$i', i.isEven ? 'm-emma' : 'm-sam', 'Vault paper $i'),
    ];
    final watch = Stopwatch()..start();
    final found = searchDocuments(
      many,
      const DocumentQuery(text: 'paper 12'),
      today: today,
      ownerNames: names,
    );
    watch.stop();

    // Both words must appear: every paper whose number contains "12".
    expect(
      {for (final entry in found) entry.id},
      {
        for (var i = 0; i < 150; i++)
          if ('$i'.contains('12')) 'h$i',
        for (var i = 0; i < 50; i++)
          if ('$i'.contains('12')) 'v$i',
      },
    );
    expect(watch.elapsedMilliseconds, lessThan(16));
  });
}
