import 'package:flutter_test/flutter_test.dart';
import 'package:nestprep/features/accounts/model/auth_user.dart';

/// What to call somebody before they have told us anything.
///
/// Every branch of it was uncovered: the fallback chain is the first text a new
/// account ever sees, and it runs on data Google supplies rather than data we
/// validate — so a missing display name, a whitespace one, or an odd email is
/// what it actually has to survive.
void main() {
  AuthUser user({String? displayName, String email = 'daniel@example.com'}) =>
      AuthUser(uid: 'uid-1', email: email, displayName: displayName);

  test('uses the display name when there is one', () {
    expect(user(displayName: 'Daniel').bestName, 'Daniel');
  });

  test('trims it, because a trailing space renders as a gap', () {
    expect(user(displayName: '  Daniel  ').bestName, 'Daniel');
  });

  test('falls back to the email local part when there is no name', () {
    expect(user().bestName, 'daniel');
  });

  test('falls back when the name is empty or only whitespace', () {
    // Google returns an empty string rather than null often enough that this
    // is the common case, not the odd one.
    expect(user(displayName: '').bestName, 'daniel');
    expect(user(displayName: '   ').bestName, 'daniel');
  });

  test('never shows the domain, which is not a name', () {
    expect(user(email: 'sam@nullstate.co.za').bestName, 'sam');
  });

  test('uses the whole string when an email has no local part', () {
    // Not a real address, but it is a string Auth could hand us, and an empty
    // greeting is worse than an odd one.
    expect(user(email: '@example.com').bestName, '@example.com');
  });

  test('uses the whole string when there is no @ at all', () {
    expect(user(email: 'daniel').bestName, 'daniel');
  });
}
