import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/meals_route.dart';
import '../../household/model/household_view.dart';
import '../../recipes/model/recipe_import_way.dart';
import '../../recipes/ui/own_recipe_access.dart';
import '../../subscriptions/model/premium_feature.dart';
import '../../subscriptions/ui/premium_gate.dart';
import '../model/frame_share_item.dart';
import '../model/shared_pdf.dart';
import '../state/pending_share.dart';
import 'share_to_frame_sheet.dart';

class ShareToFrameHost extends StatefulWidget {
  const ShareToFrameHost({required this.child, super.key});

  final Widget child;

  @override
  State<ShareToFrameHost> createState() => _ShareToFrameHostState();
}

class _ShareToFrameHostState extends State<ShareToFrameHost> {
  bool _isOpen = false;

  void _open(PendingShare pending) {
    _isOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pdf = mounted ? pending.takePdf() : null;
      final page = mounted && pdf == null ? pending.take() : null;
      if (pdf != null) {
        await _importPdf(pdf);
      } else if (page != null) {
        final canSaveAsRecipe = OwnRecipeAccess.now(context).canAddOrEdit;
        final isSaving = await showShareToFrameSheet(
          context: context,
          item: FrameSharePage(page),
          canSaveAsRecipe: canSaveAsRecipe,
        );
        if (isSaving && mounted) await _saveAsRecipe(page.url!);
      }
      if (!mounted) return;
      setState(() => _isOpen = false);
    });
  }

  Future<void> _saveAsRecipe(String link) async {
    if (!await ensurePremium(context, feature: PremiumFeature.ownRecipes)) {
      return;
    }
    if (mounted) unawaited(_openImport(link));
  }

  Future<void> _importPdf(SharedPdf pdf) async {
    if (!await ensurePremium(context, feature: PremiumFeature.ownRecipes)) {
      return;
    }
    if (mounted) unawaited(_openPdfImport(pdf));
  }

  Future<void> _openPdfImport(SharedPdf pdf) => context.push<void>(
    MealsRoute.importPdfPathFor(context.read<HouseholdView>().household.id),
    extra: pdf,
  );

  Future<void> _openImport(String link) => context.push<void>(
    MealsRoute.importRecipePathFor(
      context.read<HouseholdView>().household.id,
      RecipeImportWay.link,
    ),
    extra: link,
  );

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<PendingShare?>();
    if ((pending?.isWaiting ?? false) && !_isOpen) _open(pending!);
    return widget.child;
  }
}
