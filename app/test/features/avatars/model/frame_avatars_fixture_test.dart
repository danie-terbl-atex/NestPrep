import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/model/avatar_hemisphere_of.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/avatars/model/resolved_avatar.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

void main() {
  final fixture = jsonDecode(
    File('../functions/test/fixtures/frame_avatars.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final today = CalendarDate.parse(fixture['today']! as String);
  final hemisphere = avatarHemisphereOf(fixture['timeZone']! as String);
  final day = fixture['day']! as Map<String, Object?>;
  final household = day['household']! as Map<String, Object?>;
  final sent = {
    for (final member
        in (household['members']! as List).cast<Map<String, Object?>>())
      member['name']! as String: member['avatar'] as Map<String, Object?>?,
  };

  String baseOf(Map<String, Object?> avatar) {
    final base = avatar['base']! as Map<String, Object?>;
    return '${base.keys.single}:${base.values.single}';
  }

  group('the phone draws what the server sends the frame', () {
    for (final member
        in (fixture['members']! as List).cast<Map<String, Object?>>()) {
      final name = member['name']! as String;
      test(
        name,
        () {
          final birthday = member['birthday'] as String?;
          final resolved = ResolvedAvatar.of(
            MemberLook.fromFirestore(member['look']),
            today: today,
            hemisphere: hemisphere,
            birthday: birthday == null ? null : Birthday.parse(birthday),
          );
          final avatar = sent[name];
          if (avatar == null) {
            expect(resolved.isInitialOnly, isTrue);
            return;
          }
          expect(switch (resolved.base) {
            ResolvedInitial() => 'initial:true',
            ResolvedPreset(:final assetId) => 'preset:$assetId',
            ResolvedImage(:final hash) => 'image:$hash',
          }, baseOf(avatar));
          expect(
            {
              for (final MapEntry(:key, :value) in resolved.layers.entries)
                key.name: value,
            },
            {
              for (final layer
                  in (avatar['layers']! as List).cast<Map<String, Object?>>())
                layer['slot']! as String: layer['id']! as String,
            },
          );
        },
        skip: member['phoneAgrees'] == false
            ? 'the phone reads a malformed look more forgivingly'
            : null,
      );
    }
  });

  test('the fixture is not empty', () {
    expect(sent.values.whereType<Map<String, Object?>>().length, 9);
  });
}
