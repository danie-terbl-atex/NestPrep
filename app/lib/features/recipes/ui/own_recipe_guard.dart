import 'package:flutter/material.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import 'own_recipe_access.dart';

class OwnRecipeGuard extends StatelessWidget {
  const OwnRecipeGuard({required this.onBack, required this.child, super.key});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (OwnRecipeAccess.of(context).canAddOrEdit) return child;
    return OwnRecipeNotice(
      onBack: onBack,
      child: const NestEmptyView(
        icon: LucideIcons.lock,
        title: OwnRecipeCopy.editTitle,
        message: OwnRecipeCopy.notYours,
      ),
    );
  }
}

class OwnRecipeNotice extends StatelessWidget {
  const OwnRecipeNotice({required this.onBack, required this.child, super.key});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) => NestScaffold(
    leading: NestIconButton(
      icon: LucideIcons.arrowLeft,
      label: AppCopy.back,
      onPressed: onBack,
    ),
    title: OwnRecipeCopy.editTitle,
    body: child,
  );
}
