import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/nanny_hub_route.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../household/model/household_view.dart';
import '../state/nanny_hub_controller.dart';
import 'hub_home.dart';
import 'nanny_hub_page.dart';

/// The hub's home: who is on shift and the way into shift mode first, then the
/// latest handover, the children, the four places a carer needs, and the
/// shifts before this one. The emergency sheet is one tap away from the
/// header of every hub screen that matters in a hurry.
class NannyHubScreen extends StatelessWidget {
  const NannyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NannyHubController>();
    return NannyHubPage(
      title: NannyCopy.title,
      trailing: const [EmergencyLinkButton()],
      builder: (context, view) => HubHome(view: view, controller: controller),
    );
  }
}

/// One tap to the emergency sheet, from the header.
class EmergencyLinkButton extends StatelessWidget {
  const EmergencyLinkButton({super.key});

  @override
  Widget build(BuildContext context) {
    final householdId = context.read<HouseholdView>().household.id;
    return NestIconButton(
      icon: LucideIcons.siren,
      label: NannyShiftCopy.openEmergency,
      variant: NestIconButtonVariant.accent,
      onPressed: () =>
          context.push(NannyHubRoute.emergencyPathFor(householdId)),
    );
  }
}
