import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/links/external_link_opener.dart';
import '../model/recipe.dart';

class OwnRecipeSourceLink extends StatelessWidget {
  const OwnRecipeSourceLink({required this.recipe, super.key});

  final Recipe recipe;

  static Uri? _publicLink(String? url) => switch (Uri.tryParse(url ?? '')) {
    final link? when link.isScheme('https') || link.isScheme('http') => link,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final link = _publicLink(recipe.sourceUrl);
    if (link == null) return const SizedBox.shrink();
    final host = link.host.replaceFirst(RegExp(r'^www\.'), '');
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: NestButton(
        key: const ValueKey('own-recipe-source'),
        label: OwnRecipeCopy.fromSource(recipe.sourceName ?? host),
        icon: LucideIcons.externalLink,
        variant: NestButtonVariant.link,
        size: NestButtonSize.small,
        isExpanded: false,
        onPressed: () => context.read<ExternalLinkOpener>().open(link),
      ),
    );
  }
}
