import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/household_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/household_view.dart';

/// The way to the household from any feature tab. It is in the header rather
/// than the bottom bar because the bar belongs to the four things a household
/// does every day, and managing people is not one of them.
class HouseholdLinkButton extends StatelessWidget {
  const HouseholdLinkButton({super.key});

  @override
  Widget build(BuildContext context) {
    final householdId = context.read<HouseholdView>().household.id;
    return NestIconButton(
      icon: Icons.group_outlined,
      label: AppCopy.householdTitle,
      onPressed: () => context.go(HouseholdRoute.householdPathFor(householdId)),
    );
  }
}
