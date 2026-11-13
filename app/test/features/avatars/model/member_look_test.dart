import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_choice.dart';
import 'package:nestprep/features/avatars/model/member_avatar_record.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/household/model/household.dart';
import 'package:nestprep/features/household/model/member.dart';

void main() {
  const hash = '0123456789abcdef0123456789abcdef';

  test('a member without a look has none, and never writes one', () {
    final member = Member.fromJson({
      'id': 'm1',
      'displayName': 'Mia',
      'color': 'coral',
      'role': 'kid',
    });
    expect(member.look, isNull);
    expect(
      member.copyWith(look: const MemberLook()).toJson(),
      isNot(contains('look')),
    );
  });

  test('the look the Functions mirror is read as it is written', () {
    final member = Member.fromJson({
      'id': 'm1',
      'displayName': 'Mia',
      'color': 'coral',
      'role': 'kid',
      'look': {
        'v': 1,
        'base': 'preset:pip',
        'stage': 2,
        'wear': {'top': 'acc-crown', 'badge': 'acc-football', 'nose': 'x'},
      },
    });
    expect(member.look?.base, const PresetBase('pip'));
    expect(member.look?.stage, 2);
    expect(member.look?.wear, {
      AvatarSlot.top: 'acc-crown',
      AvatarSlot.badge: 'acc-football',
    });
  });

  test('a malformed look falls back piece by piece, never throws', () {
    expect(MemberLook.fromFirestore('nonsense'), isNull);
    final look = MemberLook.fromFirestore({
      'base': 'image:NOT-A-HASH',
      'stage': 9,
      'wear': 'hat',
    })!;
    expect(look.base, const InitialBase());
    expect(look.stage, 3);
    expect(look.wear, isEmpty);
    expect(MemberLook.fromFirestore({'base': null})!.base, const InitialBase());
    expect(AvatarBase.parse('image:$hash'), const ImageBase(hash));
  });

  test('the choice is written in the shape the rules hold it to', () {
    const choice = AvatarChoice(
      base: PresetBase('olive'),
      stage: 1,
      wear: {AvatarSlot.top: 'acc-cap'},
    );
    expect(choice.toFirestore(), {
      'base': 'preset:olive',
      'stage': 1,
      'wear': {'top': 'acc-cap'},
    });
    expect(const AvatarChoice().toFirestore(), {
      'base': 'initial',
      'wear': <String, String>{},
    });
    expect(AvatarChoice.fromFirestore(choice.toFirestore()), choice);
  });

  test('glasses come off a look that is not a Nestling', () {
    const choice = AvatarChoice(
      base: ImageBase(hash),
      wear: {AvatarSlot.face: 'acc-monocle', AvatarSlot.top: 'acc-cap'},
    );
    expect(choice.lookFor(stage: 0).wear, {AvatarSlot.top: 'acc-cap'});
  });

  test('what a member owns is read, and nothing a client may not trust', () {
    final record = MemberAvatarRecord.fromFirestore({
      'choice': {'base': 'preset:pip', 'wear': <String, Object?>{}},
      'pendingPhoto': hash,
      'owned': {
        'accessories': ['acc-crown', 3],
        'images': [hash, 'bad'],
      },
    });
    expect(record.owns('acc-crown'), isTrue);
    expect(record.ownedImages, [hash]);
    expect(record.pendingPhoto, hash);
  });

  test('a household without the shop switch has the shop open', () {
    final household = Household.fromJson({
      'id': 'h1',
      'name': 'The Parkers',
      'timeZone': 'Africa/Johannesburg',
    });
    expect(household.avatarShop, isTrue);
    expect(household.toJson(), isNot(contains('avatarShop')));
    expect(
      Household.fromJson({
        'id': 'h1',
        'name': 'The Parkers',
        'timeZone': 'Africa/Johannesburg',
        'avatarShop': false,
      }).avatarShop,
      isFalse,
    );
  });
}
