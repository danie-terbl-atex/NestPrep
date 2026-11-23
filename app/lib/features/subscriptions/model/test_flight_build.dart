/// The TestFlight build (subscriptions ADR-0014): it sells nothing, because a
/// TestFlight purchase is Apple's sandbox and never a real subscription, and
/// it offers Premium claims whatever `appConfig/flags` says. A define, so the
/// App Store build from the same source still sells; every Shorebird patch to
/// a TestFlight release must carry it (`tools/shorebird.sh ios-testflight`).
bool get isTestFlightBuild => debugTestFlightBuild ?? _testFlightDefine;

const testFlightDefineName = 'NESTPREP_TESTFLIGHT';

const _testFlightDefine = String.fromEnvironment(testFlightDefineName) == 'on';

/// Set by the tests and the design-review press; never set in the app.
bool? debugTestFlightBuild;
