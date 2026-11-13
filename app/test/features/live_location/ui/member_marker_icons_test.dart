import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/design/nest_kit.dart';
import 'package:nestprep/features/avatars/model/avatar_base.dart';
import 'package:nestprep/features/avatars/model/avatar_catalogue.g.dart';
import 'package:nestprep/features/avatars/model/member_look.dart';
import 'package:nestprep/features/avatars/model/resolved_avatar.dart';
import 'package:nestprep/features/live_location/ui/member_marker_icons.dart';
import 'package:nestprep/shared/time/calendar_date.dart';

void main() {
  ResolvedAvatar resolved(MemberLook look) => ResolvedAvatar.of(
    look,
    today: CalendarDate(2026, 11, 12),
    hemisphere: AvatarHemisphere.south,
  );

  (String, MemberColor, bool, String) key({ResolvedAvatar? avatar}) =>
      MemberMarkerIcons.keyOf(
        name: 'Mia',
        color: MemberColor.coral,
        isDark: false,
        avatar: avatar,
      );

  test('an initial is cached as it always was', () {
    expect(key(), key(avatar: ResolvedAvatar.initial));
    expect(key().$4, isEmpty);
  });

  test('a look draws a new pin when it changes, and the same pin when not', () {
    const pip = MemberLook(base: PresetBase('pip'), stage: 1);
    final grown = key(avatar: resolved(pip.copyWith(stage: 2)));
    expect(key(avatar: resolved(pip)), isNot(key()));
    expect(key(avatar: resolved(pip)), key(avatar: resolved(pip)));
    expect(key(avatar: resolved(pip)), isNot(grown));
    expect(
      key(avatar: resolved(pip.copyWith(wear: {AvatarSlot.top: 'acc-crown'}))),
      isNot(key(avatar: resolved(pip))),
    );
  });

  test('a photo pin is drawn again once its bytes arrive', () {
    final photo = resolved(
      const MemberLook(base: ImageBase('0123456789abcdef0123456789abcdef')),
    );
    expect(
      MemberMarkerIcons.keyOf(
        name: 'Mia',
        color: MemberColor.coral,
        isDark: false,
        avatar: photo,
      ),
      isNot(
        MemberMarkerIcons.keyOf(
          name: 'Mia',
          color: MemberColor.coral,
          isDark: false,
          avatar: photo,
          hasPhoto: true,
        ),
      ),
    );
  });
}
