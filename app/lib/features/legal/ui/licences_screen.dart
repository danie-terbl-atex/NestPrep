import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/package_licences.dart';
import '../state/licences_controller.dart';

/// Every open-source package and font inside this build, one row each, a tap
/// away from its licence text. Built from the kit rather than Flutter's own
/// licence page, so it reads like the rest of the app in both themes.
class LicencesScreen extends StatelessWidget {
  const LicencesScreen({super.key});

  static const path = '/account/licences';

  static String pathFor(String package) =>
      '$path/${Uri.encodeComponent(package)}';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LicencesController>();
    return NestScaffold(
      title: LegalCopy.licencesTitle,
      subtitle: LegalCopy.licencesSubtitle,
      leading: backLeading(context),
      body: NestAsyncView<List<PackageLicences>>(
        state: controller.packages,
        isEmpty: (packages) => packages.isEmpty,
        onRetry: controller.retry,
        loadingRows: 8,
        emptyBuilder: (_) => const NestEmptyView(
          title: LegalCopy.licencesEmptyTitle,
          message: LegalCopy.licencesEmptyBody,
          icon: LucideIcons.fileText,
        ),
        dataBuilder: (context, packages) => ListView.builder(
          padding: const EdgeInsets.only(bottom: NestSpace.huge),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final package = packages[index];
            return NestListRow(
              key: ValueKey(package.package),
              title: package.package,
              subtitle: LegalCopy.licenceCount(package.texts.length),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push(pathFor(package.package)),
            );
          },
        ),
      ),
    );
  }
}
