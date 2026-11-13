import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/avatar_hemisphere_of.dart';
import 'package:nestprep/features/avatars/model/avatar_moments.dart';
import 'package:nestprep/features/avatars/model/avatar_stage.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/household/model/birthday.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/avatar_moments.json').readAsStringSync(),
  ) as Map<String, Object?>;

  MomentRule ruleOf(Map<String, Object?> json) => switch (json['kind']) {
    'birthday' => const BirthdayMomentRule(),
    'easter' => EasterMomentRule(
      from: json['from']! as int,
      to: json['to']! as int,
    ),
    _ => DatesMomentRule(
      from: json['from']! as String,
      to: json['to']! as String,
      hemisphere: switch (json['hemisphere']) {
        'south' => AvatarHemisphere.south,
        'north' => AvatarHemisphere.north,
        _ => null,
      },
    ),
  };

  final moments = [
    for (final json
        in (fixture['moments']! as List).cast<Map<String, Object?>>())
      AvatarMoment(
        id: json['id']! as String,
        label: json['id']! as String,
        slot: AvatarSlot.values.byName(json['slot']! as String),
        rule: ruleOf(json['rule']! as Map<String, Object?>),
      ),
  ];

  group('the shared fixture', () {
    for (final json
        in (fixture['cases']! as List).cast<Map<String, Object?>>()) {
      test(json['name']! as String, () {
        final birthday = json['birthday'] as String?;
        final shown = avatarMomentsOn(
          today: CalendarDate.parse(json['today']! as String),
          hemisphere: avatarHemisphereOf(json['zone']! as String),
          birthday: birthday == null ? null : Birthday.parse(birthday),
          wear: MemberLook.wearFrom(json['wear']),
          moments: moments,
        );
        expect({
          for (final MapEntry(:key, :value) in shown.entries) key.name: value,
        }, json['expect']);
      });
    }

    test('Western Easter Sunday, from the earliest to the latest it falls', () {
      for (final json
          in (fixture['easter']! as List).cast<Map<String, Object?>>()) {
        expect(
          westernEaster(json['year']! as int),
          CalendarDate.parse(json['sunday']! as String),
          reason: '${json['year']}',
        );
      }
    });

    test('the stage a child\'s stars give', () {
      for (final json
          in (fixture['stages']! as List).cast<Map<String, Object?>>()) {
        expect(
          AvatarStage.forStars(
            earned: json['earned']! as int,
            bestStreak: json['bestStreak']! as int,
          ),
          json['stage'],
          reason: '$json',
        );
      }
    });

    test('the hemisphere of a household zone', () {
      for (final json
          in (fixture['hemispheres']! as List).cast<Map<String, Object?>>()) {
        expect(
          avatarHemisphereOf(json['zone']! as String).name,
          json['hemisphere'],
          reason: json['zone']! as String,
        );
      }
    });
  });

  test('every bundled moment rule is one the resolver reads', () {
    for (final moment in avatarMoments) {
      expect(moment.id, startsWith('moment-'));
      for (var day = 0; day < 366; day++) {
        isAvatarMomentOn(
          moment.rule,
          today: CalendarDate(2028, 1, 1).addDays(day),
          hemisphere: AvatarHemisphere.south,
        );
      }
    }
  });

  test('the bundled festive hat shows on Christmas in Johannesburg', () {
    final shown = avatarMomentsOn(
      today: CalendarDate(2026, 12, 25),
      hemisphere: AvatarHemisphere.south,
      birthday: null,
      wear: const {},
    );
    expect(shown[AvatarSlot.top], 'moment-festive-hat');
  });
}
