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
    HouseholdArea.calendar => LucideIcons.calendar,
    HouseholdArea.groceries => LucideIcons.shoppingBasket,
    HouseholdArea.todos => LucideIcons.circleCheck,
    HouseholdArea.meals => LucideIcons.utensils,
    HouseholdArea.documents => LucideIcons.folderOpen,
    HouseholdArea.lunch => LucideIcons.sandwich,
    HouseholdArea.familyProfiles => LucideIcons.smile,
    HouseholdArea.medical => LucideIcons.briefcaseMedical,
    HouseholdArea.homeCare => LucideIcons.sprayCan,
    HouseholdArea.nannyHub => LucideIcons.baby,
  };

  NestTileTint get _tint => switch (area) {
    HouseholdArea.calendar || HouseholdArea.todos => NestTileTint.accent,
    HouseholdArea.groceries || HouseholdArea.meals => NestTileTint.basil,
    HouseholdArea.documents || HouseholdArea.homeCare => NestTileTint.lilac,
    HouseholdArea.lunch || HouseholdArea.familyProfiles => NestTileTint.butter,
    HouseholdArea.medical || HouseholdArea.nannyHub => NestTileTint.guava,
  };
}
