import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/emergency_contact.dart';
import '../model/nanny_hub_view.dart';
import '../state/nanny_hub_controller.dart';
import 'contact_sheet.dart';
import 'emergency_call_buttons.dart';
import 'emergency_contact_row.dart';
import 'home_details_card.dart';
import 'home_details_sheet.dart';
import 'nanny_hub_page.dart';

/// The emergency sheet: the public numbers first and biggest — they work
/// whether or not anybody filled anything in — then the address to give an
/// ambulance, the people to call, each one tap away, and the medical aid.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NannyHubController>();
    return NannyHubPage(
      title: NannyCopy.emergencyTitle,
      builder: (context, view) =>
          _EmergencyBody(view: view, controller: controller),
    );
  }
}

class _EmergencyBody extends StatelessWidget {
  const _EmergencyBody({required this.view, required this.controller});

  final NannyHubView view;
  final NannyHubController controller;

  Future<void> _addContact(BuildContext context) async {
    final outcome = await showContactSheet(context: context);
    if (outcome == null) return;
    await controller.edit.addContact(outcome.draft);
  }

  Future<void> _editContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final outcome = await showContactSheet(context: context, existing: contact);
    if (outcome == null) return;
    if (outcome.isRemoval) {
      await controller.edit.removeContact(contact.id);
    } else {
      await controller.edit.updateContact(contact.id, outcome.draft);
    }
  }

  Future<void> _editHome(BuildContext context) async {
    final sheet = await showHomeDetailsSheet(
      context: context,
      sheet: view.hub.sheet,
    );
    if (sheet == null) return;
    await controller.edit.saveSheet(sheet);
  }

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    final canEdit = controller.access.canEdit;
    final contacts = view.hub.contacts;
    return ListView(
      padding: const EdgeInsets.only(bottom: NestSpace.huge),
      children: [
        Text(NannyCopy.emergencyIntro, style: nest.text.bodyStrong),
        const SizedBox(height: NestSpace.md),
        EmergencyCallButtons(onCall: controller.call),
        const SizedBox(height: NestSpace.xl),
        HomeDetailsCard(
          sheet: view.hub.sheet,
          onEdit: canEdit ? () => _editHome(context) : null,
        ),
        const SizedBox(height: NestSpace.xl),
        NestSectionHeader(
          title: NannyCopy.contacts,
          actionIcon: canEdit ? Icons.person_add_alt : null,
          actionLabel: canEdit ? NannyCopy.addContact : null,
          onAction: canEdit ? () => _addContact(context) : null,
        ),
        const SizedBox(height: NestSpace.sm),
        if (contacts.isEmpty)
          Text(
            NannyCopy.noContacts,
            style: nest.text.bodySecondary.copyWith(
              color: nest.colors.inkTertiary,
            ),
          ),
        // Parents first, the hospital last (`EmergencyContact.bySheetOrder`).
        for (final contact in contacts)
          Padding(
            key: ValueKey(contact.id),
            padding: const EdgeInsets.only(bottom: NestSpace.sm),
            child: EmergencyContactRow(
              contact: contact,
              onCall: () => controller.call(contact.dialLink),
              onEdit: canEdit ? () => _editContact(context, contact) : null,
            ),
          ),
      ],
    );
  }
}
