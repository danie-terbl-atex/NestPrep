import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/documents/model/document_share.dart';
import 'package:nestprep/features/documents/model/identity_document_hint.dart';
import 'package:nestprep/features/documents/model/offline_shelf.dart';
import 'package:nestprep/features/documents/model/share_lifetime.dart';
import 'package:nestprep/features/documents/model/share_request.dart';
import 'package:nestprep/shared/copy/share_link_copy.dart';

import '../../../support/fake_document_tools.dart';

/// The small rules of documents V2 (documents ADR-0006, ADR-0007) that live
/// on the phone: the lifetimes offered (a contract with the server), the PIN
/// the server will take, which documents ask twice, when a link is live, and
/// the offline shelf's cap.
void main() {
  group('the lifetimes offered', () {
    test('are exactly the ones createDocumentShare accepts', () {
      final policy = File(
        '../functions/src/documents/share/share_policy.ts',
      ).readAsStringSync();
      final declared = RegExp(
        r'SHARE_LIFETIME_HOURS = \[([^\]]+)\]',
      ).firstMatch(policy)?.group(1);
      expect(declared, isNotNull, reason: 'share_policy.ts moved or changed');
      final server = declared!
          .split(',')
          .map((hours) => int.parse(hours.trim()))
          .toList();
      expect(ShareLifetime.hourOptions, server);
    });

    test('each reads as a person says it', () {
      expect(ShareLifetime.hourOptions.map(ShareLinkCopy.hours).toList(), [
        '1 hour',
        '4 hours',
        '1 day',
        '3 days',
        '7 days',
      ]);
    });

    test('a shift is the same choice whoever is on it', () {
      expect(
        const ShiftLifetime(shiftId: 's1', carerName: 'Thandi'),
        const ShiftLifetime(shiftId: 's1', carerName: ''),
      );
      expect(const HoursLifetime(4), isNot(const HoursLifetime(24)));
    });
  });

  test('a PIN is 4 to 8 digits, as the server says', () {
    for (final pin in ['1234', '00000000', '2468']) {
      expect(ShareRequest.isPin(pin), isTrue, reason: pin);
    }
    for (final pin in ['123', '123456789', '12a4', '', ' 1234']) {
      expect(ShareRequest.isPin(pin), isFalse, reason: pin);
    }
  });

  group('an identity document asks twice', () {
    test('by its name or its tags', () {
      for (final name in [
        'Emma passport',
        'Sam ID',
        'Birth certificate',
        'Driver\'s licence',
        'Smart ID card',
      ]) {
        expect(
          IdentityDocumentHint.looksLikeIdentity(name: name, tags: const []),
          isTrue,
          reason: name,
        );
      }
      expect(
        IdentityDocumentHint.looksLikeIdentity(
          name: 'Scan 29 Sep',
          tags: const ['ID'],
        ),
        isTrue,
      );
    });

    test('and nothing else does', () {
      for (final name in ['Medical aid card', 'Car insurance', 'Idea list']) {
        expect(
          IdentityDocumentHint.looksLikeIdentity(name: name, tags: const []),
          isFalse,
          reason: name,
        );
      }
    });
  });

  group('a link', () {
    final now = DateTime.utc(2026, 9, 29, 12);

    test('is live while active and not yet ended', () {
      expect(
        aShare(
          's1',
          expiresAt: now.add(const Duration(minutes: 1)),
        ).isLiveAt(now),
        isTrue,
      );
      expect(aShare('s1', expiresAt: now).isLiveAt(now), isFalse);
      expect(aShare('s1').copyWith(status: 'revoked').isLiveAt(now), isFalse);
    });

    test('knows whether it came from a vault and whether it ends with a '
        'shift', () {
      final share = aShare('s1', shiftId: 'shift-1');
      expect(share.isFromVault, isTrue);
      expect(share.isUntilShiftEnds, isTrue);
      expect(aShare('s2', ownerMemberId: null).isFromVault, isFalse);
      expect(DocumentShare.active, 'active');
    });
  });

  group('the offline shelf', () {
    test('adds up the room its copies take, and knows each one', () {
      final shelf = OfflineShelf([
        anOfflineCopy('a'),
        anOfflineCopy('b', ownerMemberId: 'm-kid'),
      ]);
      expect(shelf.totalBytes, 2400);
      expect(shelf.holds(ownerMemberId: null, documentId: 'a'), isTrue);
      expect(shelf.holds(ownerMemberId: 'm-kid', documentId: 'b'), isTrue);
      // The same id in another place is another document.
      expect(shelf.holds(ownerMemberId: null, documentId: 'b'), isFalse);
    });

    test('is full at twenty', () {
      expect(
        OfflineShelf([
          for (var index = 0; index < 19; index++) anOfflineCopy('d$index'),
        ]).isFull,
        isFalse,
      );
      expect(
        OfflineShelf([
          for (var index = 0; index < 20; index++) anOfflineCopy('d$index'),
        ]).isFull,
        isTrue,
      );
    });

    test('keys a copy by household, place and document', () {
      expect(anOfflineCopy('a').key, 'h1_household_a');
      expect(anOfflineCopy('a', ownerMemberId: 'm-kid').key, 'h1_m-kid_a');
    });
  });
}
