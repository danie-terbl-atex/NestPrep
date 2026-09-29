import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/product_analytics/data/callable_paywall_open_recorder.dart';
import '../features/product_analytics/data/paywall_open_recorder.dart';
import '../features/referrals/data/callable_referral_directory.dart';
import '../features/referrals/data/firestore_referral_repository.dart';
import '../features/referrals/data/referral_directory.dart';
import '../features/referrals/data/referral_repository.dart';

/// Referrals and conversion by trigger in the app-wide graph (subscriptions
/// ADR-0002, product-analytics ADR-0002): the referral reads and callables,
/// and the recorder the paywall tells when it opens. Its own list, spread
/// into `appProviders`, so the shared file changes by one line.
List<SingleChildWidget> referralProviders() => [
  Provider<ReferralRepository>(
    create: (context) =>
        FirestoreReferralRepository(context.read<FirebaseFirestore>()),
  ),
  Provider<ReferralDirectory>(
    create: (context) =>
        CallableReferralDirectory(context.read<FirebaseFunctions>()),
  ),
  Provider<PaywallOpenRecorder>(
    create: (context) =>
        CallablePaywallOpenRecorder(context.read<FirebaseFunctions>()),
  ),
];
