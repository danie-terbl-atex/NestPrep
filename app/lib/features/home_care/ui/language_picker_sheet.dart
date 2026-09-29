import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/language/helper_language.dart';

/// Chooses a language: each by its own name first, big enough to find
/// without reading English, with its English name beside for a parent
/// choosing on somebody's behalf (home-care ADR-0006).
Future<HelperLanguage?> showLanguagePicker({
  required BuildContext context,
  required HelperLanguage current,
}) => showNestSheet<HelperLanguage>(
  context: context,
  title: HomeCareLanguageCopy.chooseLanguage,
  builder: (context) => ListView(
    shrinkWrap: true,
    children: [
      for (final language in HelperLanguage.values)
        Padding(
          padding: const EdgeInsets.only(bottom: NestSpace.xs),
          child: NestListRow(
            key: ValueKey(language),
            title: language.ownName,
            subtitle: language.englishName == language.ownName
                ? null
                : language.englishName,
            isSelected: language == current,
            leading: const NestIconTile(
              icon: Icons.translate,
              tint: NestTileTint.sky,
              size: NestSize.avatarMedium,
              iconSize: NestSize.iconMedium,
            ),
            trailing: language == current ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop(language),
          ),
        ),
    ],
  ),
);
