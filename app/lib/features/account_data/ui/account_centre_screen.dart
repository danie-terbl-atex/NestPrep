import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../../shared/ui/link_row.dart';
import '../../accounts/model/session.dart';
import '../../accounts/state/session_controller.dart';
import '../../legal/ui/about_screen.dart';
import '../../legal/ui/legal_document_screen.dart';
import '../../legal/ui/licences_screen.dart';
import 'account_export_screen.dart';
import 'delete_account_screen.dart';

/// Account and privacy (accounts ADR-0006): who is signed in, the two rights
/// a person has over their data — a copy of it, and deleting it — and the
/// pages that say what NestPrep is and how it treats them.
///
/// Reached from the account sheet on every screen's header, and outside the
/// household shell on purpose: somebody who has no household yet, or has not
/// confirmed their address, can still download or delete (both stores ask
/// that deleting is never behind anything else).
class AccountCentreScreen extends StatelessWidget {
  const AccountCentreScreen({super.key});

  static const path = '/account';

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>().session;
    final signedIn = switch (session) {
      AsyncData(value: final SignedIn value) => value,
      _ => null,
    };
    return NestScaffold(
      title: AccountDataCopy.centreTitle,
      subtitle: AccountDataCopy.centreSubtitle,
      leading: backLeading(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          if (signedIn != null)
            NestRiseIn(
              child: NestCard(
                padding: const EdgeInsets.all(NestSpace.xs),
                child: NestListRow(
                  leading: NestAvatar(
                    name: signedIn.account.displayName,
                    color: MemberColor.violet,
                  ),
                  title: signedIn.account.displayName,
                  subtitle: signedIn.user.email,
                ),
              ),
            ),
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: AccountDataCopy.yourDataSection),
          const SizedBox(height: NestSpace.sm),
          const NestRiseIn(
            index: 1,
            child: NestCard(
              padding: EdgeInsets.all(NestSpace.xs),
              child: Column(
                children: [
                  LinkRow(
                    icon: LucideIcons.download,
                    title: AccountDataCopy.downloadRow,
                    subtitle: AccountDataCopy.downloadRowHint,
                    tint: NestTileTint.lilac,
                    path: AccountExportScreen.path,
                  ),
                  LinkRow(
                    icon: LucideIcons.userMinus,
                    title: AccountDataCopy.deleteRow,
                    subtitle: AccountDataCopy.deleteRowHint,
                    tint: NestTileTint.guava,
                    path: DeleteAccountScreen.path,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          const NestSectionHeader(title: AccountDataCopy.aboutSection),
          const SizedBox(height: NestSpace.sm),
          const NestRiseIn(
            index: 2,
            child: NestCard(
              padding: EdgeInsets.all(NestSpace.xs),
              child: Column(
                children: [
                  LinkRow(
                    icon: LucideIcons.info,
                    title: LegalCopy.aboutTitle,
                    path: AboutScreen.path,
                  ),
                  LinkRow(
                    icon: LucideIcons.shieldAlert,
                    title: LegalCopy.privacyTitle,
                    path: LegalDocumentScreen.privacyPath,
                  ),
                  LinkRow(
                    icon: LucideIcons.gavel,
                    title: LegalCopy.termsTitle,
                    path: LegalDocumentScreen.termsPath,
                  ),
                  LinkRow(
                    icon: LucideIcons.fileText,
                    title: LegalCopy.licencesTitle,
                    path: LicencesScreen.path,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
