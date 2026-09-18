import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nestprep/app/backend_target.dart';
import 'package:nestprep/app/firebase_bootstrap.dart';
import 'package:nestprep/features/household/data/callable_household_directory.dart';
import 'package:nestprep/features/household/data/firestore_household_repository.dart';

/// A signed-in member of a real household in the emulator suite, for the
/// integration tests to write inside (foundation ADR-0010).
///
/// It cannot be assembled by hand, and that is the point. The rules require a
/// household whose membership map names the caller, and **only a Cloud Function
/// may write that map** (foundation ADR-0002) — so this goes through the real
/// `createHousehold` callable. A meal's `addedBy` and a task's `createdBy` must
/// also be a member profile the caller has claimed (`isOwnMember`), so the
/// member id is read back rather than invented. The first draft of these tests
/// invented both and every write was refused, correctly.
final class TestHousehold {
  const TestHousehold({
    required this.id,
    required this.memberId,
    required this.firestore,
    required this.directory,
    required this.households,
  });

  /// The household document id the callable created.
  final String id;

  /// The member profile inside it that this signed-in uid has claimed.
  final String memberId;

  final FirebaseFirestore firestore;
  final CallableHouseholdDirectory directory;
  final FirestoreHouseholdRepository households;

  /// Another household, for the next test. The emulator is not cleared between
  /// tests, so a shared household makes one test's leftovers another's mystery.
  Future<TestHousehold> freshHousehold() async {
    final householdId = await directory.createHousehold(
      name: 'Integration',
      timeZone: 'Africa/Johannesburg',
      adminDisplayName: 'Tester',
      adminColorName: 'violet',
    );
    return TestHousehold(
      id: householdId,
      memberId: await _claimedMemberIn(households, householdId),
      firestore: firestore,
      directory: directory,
      households: households,
    );
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}

/// Boots Firebase against the emulator suite the way the app does, signs in, and
/// creates the first household.
///
/// Anonymous sign-in is enough: every rule under a household begins at
/// `isMember`, and `requireUid` asks only that a uid exists. Keeping it
/// anonymous also keeps these tests about the client's write shapes rather than
/// about authorisation, which the rules suite covers from the other side.
Future<TestHousehold> signInAndCreateAHousehold() async {
  final services = await bootstrapFirebase(BackendTarget.emulator);
  await services.auth.signInAnonymously();

  final directory = CallableHouseholdDirectory(services.functions);
  final households = FirestoreHouseholdRepository(services.firestore);
  final householdId = await directory.createHousehold(
    name: 'Integration',
    timeZone: 'Africa/Johannesburg',
    adminDisplayName: 'Tester',
    adminColorName: 'violet',
  );

  return TestHousehold(
    id: householdId,
    memberId: await _claimedMemberIn(households, householdId),
    firestore: services.firestore,
    directory: directory,
    households: households,
  );
}

Future<String> _claimedMemberIn(
  FirestoreHouseholdRepository households,
  String householdId,
) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final profiles = await households.watchMembers(householdId).first;
  return profiles.firstWhere((profile) => profile.claimedBy == uid).id;
}
