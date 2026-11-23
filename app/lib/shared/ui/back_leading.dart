import 'package:flutter/material.dart';

import '../../design/nest_kit.dart';
import '../copy/app_copy.dart';

/// The back button a pushed screen carries in its header, rather than relying
/// on the system gesture alone (`FE-17`). A deep link straight to the screen
/// has nothing to pop, and then there is no button — null for the scaffold's
/// `leading`.
///
/// It asks the navigators that hold the screen, not the router. The router
/// answers from its list of matched routes, and throws when that list has
/// moved on since the button was drawn — a second tap while the screen is
/// leaving, or a shell that is showing something in place of its navigator.
Widget? backLeading(BuildContext context) => _poppable(context) == null
    ? null
    : NestIconButton(
        icon: LucideIcons.arrowLeft,
        label: AppCopy.back,
        variant: NestIconButtonVariant.plain,
        onPressed: () {
          if (context.mounted) _poppable(context)?.maybePop();
        },
      );

/// The nearest navigator with something to go back to: the screen's own, or
/// the one its shell sits in when the screen is the first in its shell.
NavigatorState? _poppable(BuildContext context) {
  var navigator = Navigator.maybeOf(context);
  while (navigator != null && !navigator.canPop()) {
    navigator = navigator.context.findAncestorStateOfType<NavigatorState>();
  }
  return navigator;
}
