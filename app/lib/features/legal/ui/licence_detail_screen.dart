import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/ui/back_leading.dart';
import '../model/package_licences.dart';
import '../state/licences_controller.dart';

/// One package's licence texts, in full. Reached from the Licences list, or
/// directly by its path.
class LicenceDetailScreen extends StatelessWidget {
  const LicenceDetailScreen({required this.package, super.key});

  static const packageParameter = 'package';

  final String package;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LicencesController>();
    final nest = NestTheme.of(context);
    // The list's state, narrowed to this one package: loading and failure
    // are the list's, and a package this build does not carry is empty.
    final state = switch (controller.packages) {
      AsyncLoading() => const AsyncLoading<PackageLicences?>(),
      AsyncFailure(:final failure) => AsyncFailure<PackageLicences?>(failure),
      AsyncData() => AsyncData<PackageLicences?>(
        controller.packageNamed(package),
      ),
    };
    return NestScaffold(
      title: package,
      subtitle: LegalCopy.licencesTitle,
      leading: backLeading(context),
      body: NestAsyncView<PackageLicences?>(
        state: state,
        isEmpty: (found) => found == null,
        onRetry: controller.retry,
        emptyBuilder: (_) => const NestEmptyView(
          title: LegalCopy.licencesEmptyTitle,
          message: LegalCopy.licencesEmptyBody,
          icon: Icons.description_outlined,
        ),
        dataBuilder: (context, found) => ListView(
          padding: const EdgeInsets.only(bottom: NestSpace.huge),
          children: [
            for (final text in found?.texts ?? const <String>[]) ...[
              NestCard(
                variant: NestCardVariant.flat,
                child: Text(text, style: nest.text.caption),
              ),
              const SizedBox(height: NestSpace.md),
            ],
          ],
        ),
      ),
    );
  }
}
