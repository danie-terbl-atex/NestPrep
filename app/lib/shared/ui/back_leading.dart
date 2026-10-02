import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/nest_kit.dart';
import '../copy/app_copy.dart';

/// The back button a pushed screen carries in its header, rather than relying
/// on the system gesture alone (`FE-17`). A deep link straight to the screen
/// has nothing to pop, and then there is no button — null for the scaffold's
/// `leading`.
Widget? backLeading(BuildContext context) => context.canPop()
    ? NestIconButton(
        icon: LucideIcons.arrowLeft,
        label: AppCopy.back,
        variant: NestIconButtonVariant.plain,
        onPressed: context.pop,
      )
    : null;
