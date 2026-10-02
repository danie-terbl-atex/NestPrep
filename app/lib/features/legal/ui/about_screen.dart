import 'package:flutter/material.dart';

import '../../../app/app_version.dart';
import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../../../shared/ui/link_row.dart';
import 'legal_document_screen.dart';
import 'licences_screen.dart';

/// Who made this, which version it is, and the documents behind it — the
/// page both stores expect an app to have (accounts ADR-0005).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const path = '/account/about';

  @override
  Widget build(BuildContext context) {
    final nest = NestTheme.of(context);
    return NestScaffold(
      title: LegalCopy.aboutTitle,
      leading: backLeading(context),
      body: ListView(
        padding: const EdgeInsets.only(bottom: NestSpace.huge),
        children: [
          const NestRiseIn(
            child: Column(
              children: [
                NestBrandMark(),
                SizedBox(height: NestSpace.md),
                NestWordmark(
                  semanticsLabel: AppCopy.appName,
                  size: NestSize.wordmarkSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: NestSpace.md),
          Text(
            LegalCopy.aboutTagline,
            style: nest.text.bodyStrong,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpace.xs),
          Text(
            LegalCopy.appVersion(AppVersion.name, AppVersion.build),
            style: nest.text.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpace.xl),
          NestRiseIn(
            index: 1,
            child: NestCard(
              variant: NestCardVariant.tinted,
              child: Text(LegalCopy.aboutBlurb, style: nest.text.body),
            ),
          ),
          const SizedBox(height: NestSpace.lg),
          const NestRiseIn(
            index: 2,
            child: NestCard(
              padding: EdgeInsets.all(NestSpace.xs),
              child: Column(
                children: [
                  LinkRow(
                    icon: Icons.privacy_tip_outlined,
                    title: LegalCopy.privacyTitle,
                    path: LegalDocumentScreen.privacyPath,
                  ),
                  LinkRow(
                    icon: Icons.gavel_outlined,
                    title: LegalCopy.termsTitle,
                    path: LegalDocumentScreen.termsPath,
                  ),
                  LinkRow(
                    icon: Icons.description_outlined,
                    title: LegalCopy.licencesTitle,
                    path: LicencesScreen.path,
                  ),
                  NestListRow(
                    leading: NestIconTile(
                      icon: Icons.mail_outline,
                      tint: NestTileTint.basil,
                      size: NestSize.avatarMedium,
                      iconSize: NestSize.iconMedium,
                    ),
                    title: LegalCopy.aboutSupport,
                    subtitle: LegalCopy.aboutSupportAddress,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: NestSpace.xl),
          Text(
            LegalCopy.aboutMadeIn,
            style: nest.text.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
