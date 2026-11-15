/**
 * Creates the account under its fixed uid or brings it back to the seed. An
 * address held by any other uid is somebody else's account: refused, never
 * deleted. An existing account keeps its password unless `--reset-password`
 * is passed, because setting one — even the same one — signs every phone
 * using the account out.
 */
export async function seedAccount(auth, { uid, email, displayName }, { password, resetPassword }) {
  const fields = { displayName, emailVerified: true, disabled: false };
  const byEmail = await auth.getUserByEmail(email).catch((error) => {
    if (error?.code === 'auth/user-not-found') return null;
    throw error;
  });
  if (byEmail !== null && byEmail.uid !== uid) {
    throw new Error(`${email} belongs to another account (${byEmail.uid}); not touching it`);
  }
  if (byEmail !== null) {
    await auth.updateUser(uid, resetPassword ? { ...fields, password } : fields);
    return `account ${email} (${uid}) refreshed${resetPassword ? ', password reset' : ''}`;
  }
  await auth.createUser({ uid, email, ...fields, password });
  return `account ${email} (${uid}) created`;
}
