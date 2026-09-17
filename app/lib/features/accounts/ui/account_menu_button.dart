import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/async/async_state.dart';
import '../../../shared/copy/app_copy.dart';
import '../model/session.dart';
import '../state/session_controller.dart';

/// The way out of the app, in the one place every screen has a header
/// (accounts phase 1). It is an icon button rather than a menu item so that
/// signing out is never two taps deep on a shared phone.
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SessionController>();
    return NestIconButton(
      icon: Icons.person_outline,
      label: AppCopy.account,
      onPressed: () => _openSheet(context, controller),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    SessionController controller,
  ) async {
    final session = controller.session;
    final signedIn = session is AsyncData<Session> && session.value is SignedIn
        ? session.value as SignedIn
        : null;
    if (signedIn == null) return;
    await showNestSheet<void>(
      context: context,
      title: AppCopy.account,
      builder: (sheetContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NestListRow(
            leading: NestAvatar(
              name: signedIn.account.displayName,
              color: MemberColor.violet,
            ),
            title: signedIn.account.displayName,
            subtitle: signedIn.user.email,
          ),
          const SizedBox(height: NestSpace.xl),
          NestButton(
            label: AppCopy.signOut,
            variant: NestButtonVariant.danger,
            icon: Icons.logout,
            onPressed: () async {
              Navigator.of(sheetContext).pop();
              await controller.signOut();
            },
          ),
        ],
      ),
    );
  }
}
