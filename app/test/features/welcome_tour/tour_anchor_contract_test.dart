import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/household/model/access_defaults.dart';
import 'package:nestprep/features/household/model/household_view.dart';
import 'package:nestprep/features/household/model/member_role.dart';
import 'package:nestprep/features/welcome_tour/model/tour_target.dart';
import 'package:nestprep/features/welcome_tour/model/welcome_tour_plan.dart';

import '../../support/fake_feature_flag_source.dart';
import '../../support/household_fixtures.dart';

/// The anchor contract (welcome-tour ADR-0002): every component a tour step
/// can ask for is placed by a real screen, with a `TourAnchor`, exactly
/// where the screen draws it. A screen that moves or removes an anchored
/// component without keeping its anchor fails here — not in a tour that
/// quietly skips the step on somebody's phone.
void main() {
  final screens = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.contains('/welcome_tour/'))
      .where((file) => !file.path.contains('/shared/copy/'))
      .toList();

  Set<TourTarget> placed() {
    final pattern = RegExp(r'TourAnchor\(\s*target:\s*TourTarget\.(\w+)');
    return {
      for (final file in screens)
        for (final match in pattern.allMatches(file.readAsStringSync()))
          TourTarget.values.byName(match.group(1)!),
    };
  }

  HouseholdView viewAs(MemberRole role) {
    final household = Fixtures.household();
    return HouseholdView(
      household: household.copyWith(
        members: {...household.members, Fixtures.thandiUid: role.name},
        access: {Fixtures.thandiUid: ?AccessDefaults.forRole(role)},
        profiles: {Fixtures.thandiUid: Fixtures.thandiMemberId},
      ),
      members: [Fixtures.sam, Fixtures.thandi, Fixtures.kid],
      viewerUid: Fixtures.thandiUid,
    );
  }

  test('there are screens to read', () {
    expect(screens.length, greaterThan(40));
  });

  test('every target a step can ask for, or fall back to, is placed', () {
    final asked = <TourTarget>{
      for (final view in [
        Fixtures.view(),
        for (final role in MemberRole.values) viewAs(role),
      ])
        for (final flags in [TestFlags.on, TestFlags.off])
          for (final isPremium in [true, false])
            for (final stop in WelcomeTourPlan(
              view: view,
              flags: flags,
              isPremium: isPremium,
            ).stops)
              ...stop.candidates,
    };
    expect(asked.difference(placed()), isEmpty);
  });

  test('and no target exists that nothing asks for or nothing places', () {
    expect(placed(), TourTarget.values.toSet());
  });
}
