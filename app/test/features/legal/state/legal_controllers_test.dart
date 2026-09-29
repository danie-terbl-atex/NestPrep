import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/legal/model/legal_document.dart';
import 'package:nestprep/features/legal/model/legal_kind.dart';
import 'package:nestprep/features/legal/model/package_licences.dart';
import 'package:nestprep/features/legal/state/legal_document_controller.dart';
import 'package:nestprep/features/legal/state/licences_controller.dart';
import 'package:nestprep/shared/async/async_state.dart';
import 'package:nestprep/shared/failure/app_failure.dart';

import '../../../support/fake_legal.dart';
import '../../../support/fake_link_opener.dart';

void main() {
  group('LegalDocumentController', () {
    test('loads the document it was made for', () async {
      final source = FakeLegalDocumentSource();
      final controller = LegalDocumentController(
        source: source,
        linkOpener: FakeLinkOpener(),
        kind: LegalKind.terms,
      );
      expect(controller.document, isA<AsyncLoading<LegalDocument>>());
      await pumpEventQueue();
      expect(source.loaded, [LegalKind.terms]);
      expect(controller.document, isA<AsyncData<LegalDocument>>());
      controller.dispose();
    });

    test('a failed load is an error with a retry that works', () async {
      final source = FakeLegalDocumentSource()
        ..failure = const UnavailableFailure();
      final controller = LegalDocumentController(
        source: source,
        linkOpener: FakeLinkOpener(),
        kind: LegalKind.privacy,
      );
      await pumpEventQueue();
      expect(controller.document, isA<AsyncFailure<LegalDocument>>());

      source.failure = null;
      await controller.retry();
      expect(controller.document, isA<AsyncData<LegalDocument>>());
      controller.dispose();
    });

    test(
      'says so when a link will not open, and stops when one does',
      () async {
        final opener = FakeLinkOpener()..opens = false;
        final controller = LegalDocumentController(
          source: FakeLegalDocumentSource(),
          linkOpener: opener,
          kind: LegalKind.privacy,
        );
        final link = Uri.parse('https://nestprep.app/privacy');
        await controller.openLink(link);
        expect(opener.opened, [link]);
        expect(controller.linkWouldNotOpen, isTrue);

        opener.opens = true;
        await controller.openLink(link);
        expect(controller.linkWouldNotOpen, isFalse);
        controller.dispose();
      },
    );
  });

  group('LicencesController', () {
    LicenseEntry entry(List<String> packages, String text) =>
        LicenseEntryWithLineBreaks(packages, text);

    test('one row per package, sorted, each with all its texts', () async {
      final controller = LicencesController(
        licences: () => Stream.fromIterable([
          entry(['provider'], 'MIT'),
          entry(['Nunito', 'another'], 'OFL'),
          entry(['provider'], 'BSD'),
        ]),
      );
      await pumpEventQueue();
      final packages =
          (controller.packages as AsyncData<List<PackageLicences>>).value;
      expect(packages.map((p) => p.package), ['another', 'Nunito', 'provider']);
      expect(controller.packageNamed('provider')?.texts, ['MIT', 'BSD']);
      expect(controller.packageNamed('missing'), isNull);
      controller.dispose();
    });

    test(
      'a registry that fails is an error, and retry reads it again',
      () async {
        var fail = true;
        final controller = LicencesController(
          licences: () => fail
              ? Stream<LicenseEntry>.error(StateError('no asset'))
              : Stream.value(entry(['a'], 'text')),
        );
        await pumpEventQueue();
        expect(controller.packages, isA<AsyncFailure<List<PackageLicences>>>());
        expect(controller.packageNamed('a'), isNull);

        fail = false;
        await controller.retry();
        expect(controller.packageNamed('a')?.texts, ['text']);
        controller.dispose();
      },
    );
  });
}
