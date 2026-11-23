import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../household/model/household_view.dart';
import '../state/premium_voucher_inbox.dart';
import 'premium_voucher_sheet.dart';
import 'premium_vouchers_offered.dart';

class PremiumVoucherHost extends StatefulWidget {
  const PremiumVoucherHost({required this.child, super.key});

  final Widget child;

  @override
  State<PremiumVoucherHost> createState() => _PremiumVoucherHostState();
}

class _PremiumVoucherHostState extends State<PremiumVoucherHost>
    with WidgetsBindingObserver {
  String? _attachedUid;
  bool _isOpening = false;
  bool _isOffered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // A voucher issued while the app was in the background is asked for again
  // (subscriptions ADR-0013); the inbox otherwise asks once per account.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_isOffered) return;
    unawaited(context.read<PremiumVoucherInbox>().refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _attach(PremiumVoucherInbox inbox, String uid) {
    if (_attachedUid == uid) return;
    _attachedUid = uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) inbox.attach(uid);
    });
  }

  void _offer() {
    _isOpening = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && context.read<PremiumVoucherInbox>().shouldOffer) {
        await showPremiumVoucherSheet(context);
      }
      if (mounted) _isOpening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _isOffered = premiumVouchersOffered(context);
    if (_isOffered) {
      final inbox = context.watch<PremiumVoucherInbox>();
      _attach(inbox, context.watch<HouseholdView>().viewerUid);
      if (inbox.shouldOffer && !_isOpening) _offer();
    }
    return widget.child;
  }
}
