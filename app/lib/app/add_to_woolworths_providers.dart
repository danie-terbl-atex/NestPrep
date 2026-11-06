import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/add_to_woolworths/data/callable_woolworths_directory.dart';
import '../features/add_to_woolworths/data/cognito_woolworths_sign_in.dart';
import '../features/add_to_woolworths/data/emulator_woolworths_sign_in.dart';
import '../features/add_to_woolworths/data/woolworths_account_sign_in.dart';
import '../features/add_to_woolworths/data/woolworths_directory.dart';
import 'backend_target.dart';

/// Woolworths in the app-wide graph (add-to-woolworths ADR-0001): the
/// phone's own sign-in to Woolworths — a stand-in on the emulator, which no
/// real account can reach — and the five callables. Its catalogue is with
/// the others in `addToCheckersProviders`.
List<SingleChildWidget> addToWoolworthsProviders() => [
  Provider<WoolworthsAccountSignIn>(
    create: (context) =>
        BackendTarget.fromEnvironment() == BackendTarget.emulator
        ? const EmulatorWoolworthsSignIn()
        : CognitoWoolworthsSignIn(),
  ),
  Provider<WoolworthsDirectory>(
    create: (context) =>
        CallableWoolworthsDirectory(context.read<FirebaseFunctions>()),
  ),
];
