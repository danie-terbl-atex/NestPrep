import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/subscriptions/data/callable_premium_voucher_directory.dart';
import '../features/subscriptions/data/premium_voucher_directory.dart';
import '../features/subscriptions/state/premium_voucher_inbox.dart';

List<SingleChildWidget> premiumVoucherProviders() => [
  Provider<PremiumVoucherDirectory>(
    create: (context) =>
        CallablePremiumVoucherDirectory(context.read<FirebaseFunctions>()),
  ),
  ChangeNotifierProvider<PremiumVoucherInbox>(
    create: (context) =>
        PremiumVoucherInbox(directory: context.read<PremiumVoucherDirectory>()),
  ),
];
