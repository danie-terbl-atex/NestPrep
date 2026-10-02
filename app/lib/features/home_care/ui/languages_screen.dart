import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/flags/feature_flag.dart';
import '../../../shared/ui/back_leading.dart';
import '../../household/model/household_view.dart';
import '../../household/model/member.dart';
import '../model/language/helper_language.dart';
import '../state/helper_language_controller.dart';
import '../state/home_care_controller.dart';
import 'language_picker_sheet.dart';
import 'language_sample_card.dart';
import 'switched_off_view.dart';

/// Who reads home care in which language (home-care ADR-0006). A helper
/// chooses her own and hears a line of it; family sees everybody's and sets a
/// helper's for her — the helper without a phone, or who cannot read the
/// English picker.
class LanguagesScreen extends StatelessWidget {
  const LanguagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeCareController>();
    final language = context.watch<HelperLanguageController>();
    final canManage = home.access.canManage;
    final viewer = context.watch<HouseholdView>().viewerMember;
    return NestScaffold(
      title: canManage
          ? HomeCareLanguageCopy.languages
          : HomeCareLanguageCopy.myLanguage,
      subtitle: canManage
          ? HomeCareLanguageCopy.languagesSubtitle
          : HomeCareLanguageCopy.myLanguageSubtitle,
      leading: backLeading(context),
      body: SwitchedOffView(
        flag: FeatureFlag.homeCareHelperLanguage,
        child: NestAsyncView<void>(
          state: language.profilesState,
          isEmpty: (_) => false,
          onRetry: language.retryProfiles,
          emptyBuilder: (_) => const SizedBox.shrink(),
          dataBuilder: (context, _) => ListView(
            padding: const EdgeInsets.only(bottom: NestSpace.huge),
            children: [
              if (language.actionFailure case final failure?) ...[
                NestBanner(
                  message: AppCopy.failure(failure),
                  tone: NestBannerTone.danger,
                  actionLabel: AppCopy.back,
                  onAction: language.dismissActionFailure,
                ),
                const SizedBox(height: NestSpace.lg),
              ],
              if (language.translationFailure case final failure?) ...[
                NestBanner(
                  message: AppCopy.failure(failure),
                  tone: NestBannerTone.warning,
                  actionLabel: AppCopy.retry,
                  onAction: () => language.retryTranslation(const [
                    HomeCareLanguageCopy.sampleLine,
                  ]),
                ),
                const SizedBox(height: NestSpace.lg),
              ],
              const NestSectionHeader(title: HomeCareLanguageCopy.yourLanguage),
              _LanguageRow(
                member: viewer,
                name: viewer?.displayName ?? HomeCareLanguageCopy.yourLanguage,
                memberId: home.access.viewerMemberId,
              ),
              const SizedBox(height: NestSpace.lg),
              const LanguageSampleCard(),
              if (canManage) ...[
                const SizedBox(height: NestSpace.lg),
                const NestSectionHeader(
                  title: HomeCareLanguageCopy.helpersHeading,
                ),
                for (final member in home.helpers)
                  if (member.id != home.access.viewerMemberId)
                    _LanguageRow(
                      member: member,
                      name: member.displayName,
                      memberId: member.id,
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One person and the language they read in; a tap chooses another.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.member,
    required this.name,
    required this.memberId,
  });

  final Member? member;
  final String name;
  final String? memberId;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<HelperLanguageController>();
    final access = context.watch<HomeCareController>().access;
    final id = memberId;
    final chosen = language.languageOf(id);
    final canSet = id != null && access.canSetLanguageOf(id);
    final person = member;
    return Padding(
      padding: const EdgeInsets.only(bottom: NestSpace.sm),
      child: NestCard(
        variant: NestCardVariant.flat,
        padding: EdgeInsets.zero,
        child: NestListRow(
          title: name,
          subtitle: chosen == null
              ? HomeCareLanguageCopy.notChosen
              : HomeCareLanguageCopy.names(chosen.ownName, chosen.englishName),
          leading: person == null
              ? const NestIconTile(
                  icon: LucideIcons.languages,
                  tint: NestTileTint.lilac,
                  size: NestSize.avatarMedium,
                  iconSize: NestSize.iconMedium,
                )
              : NestAvatar(name: person.displayName, color: person.color),
          trailing: canSet ? const Icon(LucideIcons.chevronRight) : null,
          onTap: canSet ? () => _choose(context, language, id, chosen) : null,
        ),
      ),
    );
  }

  static Future<void> _choose(
    BuildContext context,
    HelperLanguageController language,
    String memberId,
    HelperLanguage? chosen,
  ) async {
    final next = await showLanguagePicker(
      context: context,
      current: chosen ?? HelperLanguage.english,
    );
    if (next == null || next == chosen) return;
    await language.setLanguage(memberId, next);
  }
}
