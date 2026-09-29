import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../state/nanny_hub_controller.dart';
import 'child_card_body.dart';
import 'nanny_hub_page.dart';
import 'nanny_hub_screen.dart';

/// One child's card: what they cannot eat and what they take, first and
/// always; then their routine, what they like, what comforts them and how to
/// settle them. A parent — or anybody whose hub is `edit` — changes each
/// section from its own corner.
class ChildCardScreen extends StatelessWidget {
  const ChildCardScreen({required this.childId, super.key});

  final String childId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NannyHubController>();
    return NannyHubPage(
      title: NannyCopy.title,
      trailing: const [EmergencyLinkButton()],
      // A child removed from the household while their card is open: said,
      // rather than shown as blank.
      isEmpty: (view) => view.childById(childId) == null,
      emptyBuilder: (_) => const NestEmptyView(
        title: NannyCopy.childGoneTitle,
        message: NannyCopy.childGoneBody,
        icon: Icons.person_off_outlined,
      ),
      builder: (context, view) => ChildCardBody(
        child: view.childById(childId)!,
        controller: controller,
      ),
    );
  }
}
