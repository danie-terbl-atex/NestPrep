import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design/nest_kit.dart';
import '../../../shared/copy/app_copy.dart';
import '../../../shared/log/app_log.dart';
import '../data/beta_numbers_repository.dart';
import 'beta_numbers_screen.dart';

/// The way to the Beta numbers screen, in the account sheet — offered only to
/// an account holding the reader claim (product-analytics ADR-0001).
///
/// For everybody else it takes no space at all. Hiding it is a courtesy, not
/// the protection: `firestore.rules` refuses the numbers to anyone without the
/// claim, so a household that found the path would see only the error state.
class BetaNumbersLink extends StatefulWidget {
  const BetaNumbersLink({this.onOpen, super.key});

  /// Called just before navigating, so the sheet the link sits in can close.
  final VoidCallback? onOpen;

  @override
  State<BetaNumbersLink> createState() => _BetaNumbersLinkState();
}

class _BetaNumbersLinkState extends State<BetaNumbersLink> {
  bool _canRead = false;

  @override
  void initState() {
    super.initState();
    _check(context.read<BetaNumbersRepository>());
  }

  Future<void> _check(BetaNumbersRepository repository) async {
    final bool canRead;
    try {
      canRead = await repository.canRead();
    } on Exception catch (error) {
      // Not being able to tell is the same answer as "no": the link stays
      // hidden, which costs a reader one sign-out and nobody else anything.
      // It is logged so a reader who never sees it can be diagnosed.
      AppLog.failure('check analytics reader', code: 'claims', error: error);
      return;
    }
    if (mounted && canRead != _canRead) setState(() => _canRead = canRead);
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRead) return const SizedBox.shrink();
    const copy = AppCopy.productAnalytics;
    return Padding(
      padding: const EdgeInsets.only(top: NestSpace.lg),
      child: NestButton(
        label: copy.openLink,
        variant: NestButtonVariant.outline,
        icon: Icons.insights_outlined,
        onPressed: () {
          // Taken before the sheet closes, while this context still has a
          // router above it.
          final router = GoRouter.of(context);
          widget.onOpen?.call();
          router.push<void>(BetaNumbersScreen.path);
        },
      ),
    );
  }
}
