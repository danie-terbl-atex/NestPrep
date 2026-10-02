import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../model/household_area.dart';

/// The icon tile that stands for an area wherever access is shown — the
/// editor, the people screen, "what you can use here". The name beside it is
/// the signal; the icon and its tint only help the eye (`FE-13`).
class AreaTile extends StatelessWidget {
  const AreaTile({required this.area, super.key});

  final HouseholdArea area;

  @override
  Widget build(BuildContext context) => NestIconTile(
    icon: _icon,
    tint: _tint,
    size: NestSize.avatarMedium,
    iconSize: NestSize.iconMedium,
  );

  IconData get _icon => switch (area) {
    HouseholdArea.calendar => Icons.calendar_today_outlined,
    HouseholdArea.groceries => Icons.shopping_basket_outlined,
    HouseholdArea.todos => Icons.check_circle_outline,
    HouseholdArea.meals => Icons.restaurant_outlined,
    HouseholdArea.documents => Icons.folder_shared_outlined,
    HouseholdArea.lunch => Icons.lunch_dining_outlined,
    HouseholdArea.familyProfiles => Icons.face_outlined,
    HouseholdArea.medical => Icons.medical_services_outlined,
    HouseholdArea.homeCare => Icons.cleaning_services_outlined,
    HouseholdArea.nannyHub => Icons.child_care_outlined,
  };

  NestTileTint get _tint => switch (area) {
    HouseholdArea.calendar || HouseholdArea.todos => NestTileTint.accent,
    HouseholdArea.groceries || HouseholdArea.meals => NestTileTint.basil,
    HouseholdArea.documents || HouseholdArea.homeCare => NestTileTint.lilac,
    HouseholdArea.lunch || HouseholdArea.familyProfiles => NestTileTint.butter,
    HouseholdArea.medical || HouseholdArea.nannyHub => NestTileTint.guava,
  };
}
