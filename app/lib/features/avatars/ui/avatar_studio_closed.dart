import 'package:flutter/widgets.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/failure/app_failure.dart';
import '../../../shared/ui/back_leading.dart';

class AvatarStudioClosed extends StatelessWidget {
  const AvatarStudioClosed({super.key});

  @override
  Widget build(BuildContext context) => NestScaffold(
    leading: backLeading(context),
    body: NestEmptyView(
      title: AvatarCopy.changePicture,
      message: AppCopy.failure(const PermissionDeniedFailure()),
      icon: LucideIcons.lockKeyhole,
    ),
  );
}
